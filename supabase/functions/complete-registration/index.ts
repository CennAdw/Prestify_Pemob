import { corsHeaders } from "../_shared/cors.ts";
import { errorResponse, jsonResponse } from "../_shared/response.ts";
import {
  createServiceClient,
  createUserClient,
} from "../_shared/supabase.ts";
import {
  isAcademicIdentifier,
  isUpiEmail,
  normalizeEmail,
  normalizeIdentifier,
  normalizeSkills,
} from "../_shared/validation.ts";

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return errorResponse(405, "Method tidak didukung.", "METHOD_NOT_ALLOWED");
  }

  try {
    const authorization = request.headers.get("Authorization") ?? "";
    const body = await request.json();
    const requestEmail = normalizeEmail(body.email);
    if (!requestEmail) {
      return errorResponse(
        400,
        "Email pendaftaran tidak dikirim.",
        "INVALID_REGISTRATION_DATA",
      );
    }

    let profile: { id: string; role: string; email: string } | null = null;
    let email = requestEmail;

    const service = createServiceClient();

    if (authorization) {
      const userClient = createUserClient(authorization);
      const { data: authData, error: authError } = await userClient.auth.getUser();
      if (authError || !authData.user) {
        return errorResponse(401, "Session login tidak valid.", "UNAUTHORIZED");
      }

      email = normalizeEmail(authData.user.email);
      if (!isUpiEmail(email)) {
        return errorResponse(
          403,
          "Prestify hanya menerima email @upi.edu.",
          "INVALID_EMAIL_DOMAIN",
        );
      }
      if (email !== requestEmail) {
        return errorResponse(
          403,
          "Email yang dikirim tidak cocok dengan akun yang diautentikasi.",
          "INVALID_EMAIL",
        );
      }

      const { data: authProfile, error: profileError } = await service
        .from("users")
        .select("id, role, email")
        .eq("id", authData.user.id)
        .single();
      if (profileError || !authProfile) {
        return errorResponse(
          404,
          "Profil pengguna belum tersedia.",
          "PROFILE_NOT_FOUND",
        );
      }
      profile = authProfile;
    } else {
      const { data: emailProfile, error: profileError } = await service
        .from("users")
        .select("id, role, email")
        .eq("email", requestEmail)
        .single();
      if (profileError || !emailProfile) {
        return errorResponse(
          404,
          "Profil pengguna belum tersedia.",
          "PROFILE_NOT_FOUND",
        );
      }
      profile = emailProfile;
    }

    const name = String(body.name ?? "").trim();
    const academicIdentifier = normalizeIdentifier(body.academic_identifier);
    const faculty = String(body.faculty ?? "").trim();
    const studyProgram = String(body.study_program ?? "").trim();
    const batchYear = Number(body.batch_year);
    const skills = normalizeSkills(body.skills);

    if (!name || !faculty) {
      return errorResponse(
        400,
        "Nama dan fakultas wajib diisi.",
        "INVALID_REGISTRATION_DATA",
      );
    }
    if (skills.length === 0) {
      return errorResponse(
        400,
        "Isi minimal satu skill atau bidang keahlian.",
        "INVALID_REGISTRATION_DATA",
      );
    }

    const isLecturer = profile.role === "lecturer";
    let savedIdentifier = academicIdentifier;
    if (isLecturer) {
      const { data: allowlistedLecturer, error: allowlistError } = await service
        .from("lecturer_allowlist")
        .select("nidn")
        .eq("email", email)
        .eq("is_active", true)
        .maybeSingle();
      if (allowlistError) throw allowlistError;
      savedIdentifier = normalizeIdentifier(allowlistedLecturer?.nidn);
      if (!isAcademicIdentifier(savedIdentifier)) {
        return errorResponse(
          400,
          "NIDN dosen belum dikonfigurasi oleh pengelola Prestify.",
          "LECTURER_IDENTIFIER_NOT_CONFIGURED",
        );
      }
    } else if (!isAcademicIdentifier(savedIdentifier)) {
      return errorResponse(
        400,
        "NIM wajib diisi menggunakan angka.",
        "INVALID_REGISTRATION_DATA",
      );
    }

    if (!isLecturer && (!studyProgram || !Number.isInteger(batchYear))) {
      return errorResponse(
        400,
        "Program studi dan angkatan wajib diisi untuk mahasiswa.",
        "INVALID_REGISTRATION_DATA",
      );
    }

    if (isLecturer) {
      const { data: duplicateLecturer } = await service
        .from("lecturers")
        .select("id")
        .eq("nidn", savedIdentifier)
        .neq("id", profile.id)
        .maybeSingle();
      if (duplicateLecturer) {
        return errorResponse(
          409,
          "NIDN sudah digunakan oleh akun lain.",
          "IDENTIFIER_ALREADY_USED",
        );
      }
    } else {
      const { data: duplicateStudent } = await service
        .from("users")
        .select("id")
        .eq("nim", savedIdentifier)
        .neq("id", profile.id)
        .maybeSingle();
      if (duplicateStudent) {
        return errorResponse(
          409,
          "NIM sudah digunakan oleh akun lain.",
          "IDENTIFIER_ALREADY_USED",
        );
      }
    }

    const { error: updateError } = await service
      .from("users")
      .update({
        name,
        nim: isLecturer ? null : savedIdentifier,
        faculty,
        study_program: isLecturer ? null : studyProgram,
        batch_year: isLecturer ? null : batchYear,
        skills: skills.join(", "),
        registration_completed: true,
        updated_at: new Date().toISOString(),
      })
      .eq("id", profile.id);
    if (updateError) throw updateError;

    if (isLecturer) {
      const { error: lecturerError } = await service.from("lecturers").upsert({
        id: profile.id,
        name,
        email,
        nidn: savedIdentifier,
        faculty,
        expertise: skills.join(", "),
        updated_at: new Date().toISOString(),
      });
      if (lecturerError) throw lecturerError;
    }

    return jsonResponse(200, {
      message: "Data pendaftaran berhasil disimpan.",
      role: profile.role,
    });
  } catch (error) {
    console.error("[complete-registration]", error);
    return errorResponse(
      500,
      "Data pendaftaran gagal disimpan.",
      "INTERNAL_ERROR",
    );
  }
});
