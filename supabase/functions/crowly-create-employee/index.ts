import { createClient } from 'npm:@supabase/supabase-js@2';

// Separado do adaptador Deno para permitir testes de autorizacao sem rede.
export type CreateEmployeeDeps = {
  authenticate: (jwt: string) => Promise<{ id: string } | null>;
  adminAllowed: (userId: string) => Promise<boolean>;
  createEmployee: (input: { email: string; password: string; name: string; adminId: string }) => Promise<{ id: string }>;
};
const headers = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type, x-client-info',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Content-Type': 'application/json',
};
function result(status: number, message: unknown): Response {
  return new Response(JSON.stringify(message), {status, headers});
}
export function createHandler(deps: CreateEmployeeDeps) {
  return async (req: Request): Promise<Response> => {
    if (req.method === 'OPTIONS') return new Response('ok', {headers});
    if (req.method !== 'POST') return result(405, {error:'Metodo nao permitido.'});
    const auth = req.headers.get('Authorization') ?? '';
    if (!auth.startsWith('Bearer ')) return result(401,{error:'Entre na sua conta.'});
    try {
      const user = await deps.authenticate(auth.slice(7));
      if (!user) return result(401,{error:'Sessao invalida. Entre novamente.'});
      if (!await deps.adminAllowed(user.id)) return result(403,{error:'Cadastro exclusivo do administrador.'});
      const raw = await req.text();
      if (raw.length > 4096) return result(413,{error:'Dados muito grandes.'});
      let body: Record<string, unknown>;
      try {body=JSON.parse(raw);} catch {return result(400,{error:'Dados invalidos.'});}
      if (!body || Array.isArray(body) || typeof body!=='object') return result(400,{error:'Dados invalidos.'});
      const name=typeof body.full_name==='string' ? body.full_name.trim() : '';
      const email=typeof body.email==='string' ? body.email.trim().toLowerCase() : '';
      const password=typeof body.password==='string' ? body.password : '';
      if (!name || name.length>100 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || email.length>254)
        return result(400,{error:'Informe nome e e-mail validos.'});
      if (password.length<12 || password.length>128)
        return result(400,{error:'A senha inicial deve ter entre 12 e 128 caracteres.'});
      // Ignora qualquer papel, ID ou equipe fornecidos pelo cliente.
      const created=await deps.createEmployee({email,password,name,adminId:user.id});
      return result(201,{id:created.id,email,full_name:name,role:'staff'});
    } catch {
      // Nunca registra senha, corpo, token, service_role ou detalhes internos.
      return result(400,{error:'Nao foi possivel cadastrar. Confira se o e-mail ja existe, a politica de senha e a configuracao do cadastro.'});
    }
  };
}

const url=Deno.env.get('SUPABASE_URL');
const serviceKey=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
if (!url || !serviceKey) throw new Error('Configuracao de servidor ausente.');
// Chave privilegiada somente no servidor, nunca no Flutter ou ESP32.
const server=createClient(url,serviceKey,{auth:{persistSession:false,autoRefreshToken:false}});
Deno.serve(createHandler({
  authenticate:async jwt => {
    const {data,error}=await server.auth.getUser(jwt);
    return error ? null : data.user;
  },
  adminAllowed:async id => {
    const {data,error}=await server.from('crowly_members').select('id')
      .eq('id',id).eq('workspace_id',id).eq('role','admin').eq('enabled',true).maybeSingle();
    return !error && data!==null;
  },
  createEmployee:async ({email,password,name,adminId}) => {
    // O trigger SQL revalida o admin e insere o membro na mesma transacao Auth.
    const {data,error}=await server.auth.admin.createUser({
      email,password,email_confirm:true,
      user_metadata:{full_name:name},
      app_metadata:{crowly_provisioned_by:adminId,crowly_role:'staff'},
    });
    if (error || !data.user) throw new Error('Cadastro recusado.');
    return {id:data.user.id};
  },
}));
