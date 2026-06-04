import { corsHeaders } from "../_shared/cors.ts";
import { hashVerificationCode } from "../_shared/hash.ts";
import { errorResponse, jsonResponse } from "../_shared/response.ts";
import { createServiceClient } from "../_shared/supabase.ts";
import { isUpiEmail, normalizeEmail } from "../_shared/validation.ts";

const resendCooldownSeconds = 60;
const maxSendsPerHour = 5;
const codeLifetimeMinutes = 10;

function requiredSecret(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Secret ${name} belum dikonfigurasi.`);
  return value;
}

function generateCode(): string {
  const bytes = new Uint32Array(1);
  crypto.getRandomValues(bytes);
  return String(100000 + (bytes[0] % 900000));
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
    if (!isUpiEmail(email)) {
      return errorResponse(
        400,
        "Email wajib menggunakan domain @upi.edu.",
        "INVALID_EMAIL_DOMAIN",
      );
    }

    const service = createServiceClient();
    const { data: profile } = await service
      .from("users")
      .select("id, email_verified_at, registration_completed")
      .eq("email", email)
      .maybeSingle();

    if (!profile || !profile.registration_completed) {
      return jsonResponse(200, {
        message:
          "Jika akun terdaftar, kode verifikasi akan dikirim ke email UPI.",
      });
    }
    if (profile.email_verified_at) {
      return jsonResponse(200, { message: "Email sudah terverifikasi." });
    }

    const { data: existing } = await service
      .from("email_verification_codes")
      .select("last_sent_at, sent_count, window_started_at")
      .eq("user_id", profile.id)
      .maybeSingle();

    const now = new Date();
    const lastSentAt = existing?.last_sent_at
      ? new Date(existing.last_sent_at)
      : null;
    if (
      lastSentAt &&
      now.getTime() - lastSentAt.getTime() < resendCooldownSeconds * 1000
    ) {
      return errorResponse(
        429,
        "Tunggu 60 detik sebelum mengirim ulang kode.",
        "RESEND_COOLDOWN",
      );
    }

    const windowStartedAt = existing?.window_started_at
      ? new Date(existing.window_started_at)
      : now;
    const withinWindow =
      now.getTime() - windowStartedAt.getTime() < 60 * 60 * 1000;
    const sentCount = withinWindow ? Number(existing?.sent_count ?? 0) : 0;
    if (sentCount >= maxSendsPerHour) {
      return errorResponse(
        429,
        "Batas pengiriman kode tercapai. Coba lagi satu jam kemudian.",
        "HOURLY_LIMIT_REACHED",
      );
    }

    const code = generateCode();
    const codeHash = await hashVerificationCode(
      code,
      requiredSecret("VERIFICATION_CODE_PEPPER"),
    );
    const expiresAt = new Date(
      now.getTime() + codeLifetimeMinutes * 60 * 1000,
    );

    const resendResponse = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${requiredSecret("RESEND_API_KEY")}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: requiredSecret("RESEND_FROM_EMAIL"),
        to: [email],
        subject: "Kode verifikasi Prestify",
        text:
          `Kode verifikasi Prestify kamu adalah ${code}. Kode berlaku selama ${codeLifetimeMinutes} menit.`,
        html: `
          <div style="font-family:Arial,sans-serif;max-width:560px;margin:auto;padding:24px">
            <h2 style="color:#043A95">Verifikasi email Prestify</h2>
            <p>Halo,</p>
            <p>Gunakan kode berikut untuk memverifikasi email UPI kamu:</p>
            <div style="font-size:32px;font-weight:700;letter-spacing:8px;color:#021C41;padding:18px 0">
              ${code}
            </div>
            <p>Kode berlaku selama ${codeLifetimeMinutes} menit. Jangan bagikan kode ini kepada siapa pun.</p>
          </div>
        `,
      }),
    });

    if (!resendResponse.ok) {
      console.error(
        "[send-verification-code] Resend error:",
        resendResponse.status,
        await resendResponse.text(),
      );
      return errorResponse(
        502,
        "Email verifikasi gagal dikirim oleh Resend.",
        "RESEND_FAILED",
      );
    }

    const { error: upsertError } = await service
      .from("email_verification_codes")
      .upsert({
        user_id: profile.id,
        email,
        code_hash: codeHash,
        expires_at: expiresAt.toISOString(),
        consumed_at: null,
        attempts: 0,
        sent_count: sentCount + 1,
        window_started_at: withinWindow
          ? windowStartedAt.toISOString()
          : now.toISOString(),
        last_sent_at: now.toISOString(),
        updated_at: now.toISOString(),
      });
    if (upsertError) throw upsertError;

    return jsonResponse(200, {
      message: "Kode verifikasi telah dikirim ke email UPI.",
    });
  } catch (error) {
    console.error("[send-verification-code]", error);
    return errorResponse(
      500,
      "Kode verifikasi gagal dikirim.",
      "INTERNAL_ERROR",
    );
  }
});
