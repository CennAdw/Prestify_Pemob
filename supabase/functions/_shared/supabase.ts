import { createClient, SupabaseClient } from "npm:@supabase/supabase-js@2";

function requiredEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Secret ${name} belum dikonfigurasi.`);
  return value;
}

export function createServiceClient(): SupabaseClient {
  return createClient(
    requiredEnv("SUPABASE_URL"),
    requiredEnv("SUPABASE_SERVICE_ROLE_KEY"),
    { auth: { persistSession: false, autoRefreshToken: false } },
  );
}

export function createAnonClient(): SupabaseClient {
  return createClient(
    requiredEnv("SUPABASE_URL"),
    requiredEnv("SUPABASE_ANON_KEY"),
    { auth: { persistSession: false, autoRefreshToken: false } },
  );
}

export function createUserClient(authorization: string): SupabaseClient {
  return createClient(
    requiredEnv("SUPABASE_URL"),
    requiredEnv("SUPABASE_ANON_KEY"),
    {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    },
  );
}
