import { createClient } from 'npm:@supabase/supabase-js@2';
import { JWT } from 'npm:google-auth-library@9';
import serviceAccount from '../service-account.json' with {
  type: 'json'
};
const supabase = createClient(Deno.env.get('SUPABASE_URL'), Deno.env.get('SUPABASE_SERVICE_ROLE_KEY'));
Deno.serve(async (req)=>{
  const payload = await req.json();
  const { data } = await supabase.from('profiles').select('fcm_token').eq('id', payload.receiver_id).single();
  const fcmToken = data?.fcm_token;
  if (!fcmToken) {
    return new Response(JSON.stringify({
      error: 'No FCM token found'
    }), {
      status: 400
    });
  }
  const accessToken = await getAccessToken({
    clientEmail: serviceAccount.client_email,
    privateKey: serviceAccount.private_key
  });
  const res = await fetch(`https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${accessToken}`
    },
    body: JSON.stringify({
      message: {
        token: fcmToken,
        notification: {
          title: `Journey Shared by ${payload.sender_name}`,
          body: `Pickup: ${payload.pickup_address}\nDestination: ${payload.destination_address}`
        },
        data: {
          journey_id: payload.journey_id,
          sender_id: payload.sender_id
        }
      }
    })
  });
  const resData = await res.json();
  return new Response(JSON.stringify(resData), {
    headers: {
      'Content-Type': 'application/json'
    }
  });
});
const getAccessToken = ({ clientEmail, privateKey })=>{
  return new Promise((resolve, reject)=>{
    const jwtClient = new JWT({
      email: clientEmail,
      key: privateKey,
      scopes: [
        'https://www.googleapis.com/auth/firebase.messaging'
      ]
    });
    jwtClient.authorize((err, tokens)=>{
      if (err) return reject(err);
      resolve(tokens.access_token);
    });
  });
};
