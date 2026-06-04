import { corsHeaders } from "../_shared/cors.ts";
import { errorResponse, jsonResponse } from "../_shared/response.ts";
import {
  createAnonClient,
  createServiceClient,
} from "../_shared/supabase.ts";
import {
  isAcademicIdentifier,
  isUpiEmail,
  normalizeIdentifier,
} from "../_shared/validation.ts";

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return errorResponse(405, "Method tidak didukung.", "METHOD_NOT_ALLOWED");
  }

  try {
    const body = await request.json();
    const identifier = normalizeIdentifier(body.identifier);
    const password = String(body.password ?? "");
    if (!isAcademicIdentifier(identifier) || !password) {
      return errorResponse(
        400,
        "NIM atau NIDN dan password wajib diisi.",
        "INVALID_LOGIN_DATA",
      );
    }

    const service = createServiceClient();
    let { data: profile } = await service
      .from("users")
      .select("id, email, email_verified_at, registration_completed")
      .eq("nim", identifier)
      .maybeSingle();

    if (!profile) {
      const { data: lecturer } = await service
        .from("lecturers")
        .select("id")
        .eq("nidn", identifier)
        .maybeSingle();
      if (lecturer) {
        const { data: lecturerProfile } = await service
          .from("users")
          .select("id, email, email_verified_at, registration_completed")
          .eq("id", lecturer.id)
          .maybeSingle();
        profile = lecturerProfile;
      }
    }

    if (!profile || !isUpiEmail(profile.email)) {
      return errorResponse(
        401,
        "NIM atau NIDN dan password tidak sesuai.",
        "INVALID_CREDENTIALS",
      );
    }

    const auth = createAnonClient();
    const { data: authData, error: authError } = await auth.auth
      .signInWithPassword({
        email: profile.email,
        password,
      });
    if (authError || !authData.session) {
      console.warn("[login-with-nim] Auth ditolak untuk identifier:", identifier);
      return errorResponse(
        401,
        "NIM atau NIDN dan password tidak sesuai.",
        "INVALID_CREDENTIALS",
      );
    }

    if (!profile.email_verified_at) {
      await auth.auth.signOut();
      return errorResponse(
        403,
        "Email belum diverifikasi. Masukkan kode yang dikirim ke email UPI.",
        "EMAIL_NOT_VERIFIED",
        { email: profile.email },
      );
    }

    return jsonResponse(200, {
      access_token: authData.session.access_token,
      refresh_token: authData.session.refresh_token,
      expires_at: authData.session.expires_at,
      registration_completed: profile.registration_completed,
    });
  } catch (error) {
    console.error("[login-with-nim]", error);
    return errorResponse(500, "Login gagal diproses.", "INTERNAL_ERROR");
  }
});
