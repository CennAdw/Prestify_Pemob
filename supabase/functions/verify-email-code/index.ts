import { corsHeaders } from "../_shared/cors.ts";
import { hashVerificationCode, safeEqual } from "../_shared/hash.ts";
import { errorResponse, jsonResponse } from "../_shared/response.ts";
import { createServiceClient } from "../_shared/supabase.ts";
import { isUpiEmail, normalizeEmail } from "../_shared/validation.ts";

const maxVerificationAttempts = 5;

function requiredSecret(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Secret ${name} belum dikonfigurasi.`);
  return value;
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return errorResponse(405, "Method tidak didukung.", "METHOD_NOT_ALLOWED");
  }

  try {
    const body = await request.json();
    const email = normalizeEmail(body.email);
    const code = String(body.code ?? "").trim();
    if (!isUpiEmail(email) || !/^[0-9]{6}$/.test(code)) {
      return errorResponse(
        400,
        "Email atau kode verifikasi tidak valid.",
        "INVALID_VERIFICATION_DATA",
      );
    }

    const service = createServiceClient();
    const { data: profile } = await service
      .from("users")
      .select("id, email_verified_at")
      .eq("email", email)
      .maybeSingle();
    if (!profile) {
      return errorResponse(
        400,
        "Email atau kode verifikasi tidak valid.",
        "INVALID_VERIFICATION_CODE",
      );
    }
    if (profile.email_verified_at) {
      return jsonResponse(200, { message: "Email sudah terverifikasi." });
    }

    const { data: verification } = await service
      .from("email_verification_codes")
      .select("code_hash, expires_at, consumed_at, attempts")
      .eq("user_id", profile.id)
      .maybeSingle();
    if (!verification || verification.consumed_at) {
      return errorResponse(
        400,
        "Kode verifikasi tidak ditemukan. Kirim ulang kode baru.",
        "INVALID_VERIFICATION_CODE",
      );
    }
    if (new Date(verification.expires_at).getTime() < Date.now()) {
      return errorResponse(
        400,
        "Kode verifikasi sudah kedaluwarsa. Kirim ulang kode baru.",
        "VERIFICATION_CODE_EXPIRED",
      );
    }
    if (Number(verification.attempts) >= maxVerificationAttempts) {
      return errorResponse(
        429,
        "Terlalu banyak percobaan. Kirim ulang kode baru.",
        "TOO_MANY_ATTEMPTS",
      );
    }

    const codeHash = await hashVerificationCode(
      code,
      requiredSecret("VERIFICATION_CODE_PEPPER"),
    );
    if (!safeEqual(codeHash, verification.code_hash)) {
      await service
        .from("email_verification_codes")
        .update({
          attempts: Number(verification.attempts) + 1,
          updated_at: new Date().toISOString(),
        })
        .eq("user_id", profile.id);
      return errorResponse(
        400,
        "Kode verifikasi tidak sesuai.",
        "INVALID_VERIFICATION_CODE",
      );
    }

    const verifiedAt = new Date().toISOString();
    const { error: userError } = await service
      .from("users")
      .update({ email_verified_at: verifiedAt, updated_at: verifiedAt })
      .eq("id", profile.id);
    if (userError) throw userError;

    const { error: codeError } = await service
      .from("email_verification_codes")
      .update({ consumed_at: verifiedAt, updated_at: verifiedAt })
      .eq("user_id", profile.id);
    if (codeError) throw codeError;

    return jsonResponse(200, {
      message: "Email berhasil diverifikasi. Silakan login menggunakan NIM.",
    });
  } catch (error) {
    console.error("[verify-email-code]", error);
    return errorResponse(
      500,
      "Verifikasi email gagal diproses.",
      "INTERNAL_ERROR",
    );
  }
});
