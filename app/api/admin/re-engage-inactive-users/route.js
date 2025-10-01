import { createServiceClient } from '@/libs/supabase/server';
import { sendEmail } from '@/libs/resend';

export async function POST(request) {
  try {
    const supabase = createServiceClient();
    
    // Test service client connection
    console.log('Service client created successfully');
    
    // Get users who haven't signed in for over a week
    const oneWeekAgo = new Date();
    oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);
    
    console.log('Fetching inactive users since:', oneWeekAgo.toISOString());
    
    // Get inactive users based on created_at (since last_sign_in_at doesn't exist)
    // We'll consider users inactive if they haven't been created recently and haven't updated their profile
    const { data: inactiveUsers, error: usersError } = await supabase
      .from('profiles')
      .select(`
        id, email, first_name, last_name, created_at, updated_at
      `)
      .lt('created_at', oneWeekAgo.toISOString())
      .not('email', 'is', null);

    if (usersError) {
      console.error('Error fetching inactive users:', usersError);
      console.error('Error details:', JSON.stringify(usersError, null, 2));
      return Response.json({ 
        error: 'Failed to fetch inactive users', 
        details: usersError.message,
        code: usersError.code 
      }, { status: 500 });
    }

    let emailsSent = 0;
    const errors = [];

    // Send re-engagement emails to each inactive user
    for (const user of inactiveUsers || []) {
      try {
        // Check if user has email notifications enabled
        const { data: settings } = await supabase
          .from('user_settings')
          .select('email_notifications')
          .eq('user_id', user.id)
          .single();

        if (settings && !settings.email_notifications) {
          continue; // Skip users who have disabled email notifications
        }

        // Get user's first dog name separately
        const { data: userDogs } = await supabase
          .from('dogs')
          .select('name')
          .eq('owner_id', user.id)
          .limit(1);
        
        const userDogName = userDogs?.[0]?.name || 'your dog';

        // Calculate days since account creation (since we don't have last_sign_in_at)
        const accountCreated = new Date(user.created_at);
        const daysSinceAccountCreated = Math.floor((Date.now() - accountCreated.getTime()) / (1000 * 60 * 60 * 24));

        // Send re-engagement email
        await sendEmail({
          to: user.email,
          subject: `We miss you at ShareSkippy! 🐾`,
          html: `<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>We miss you at ShareSkippy</title>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <!-- Preheader (hidden in most clients) -->
    <style>
      .preheader { display:none !important; visibility:hidden; opacity:0; color:transparent; height:0; width:0; overflow:hidden; mso-hide:all; }
      a { color: #7c3aed; }
    </style>
  </head>
  <body style="margin:0; padding:0; background-color:#f9fafb;">
    <div class="preheader">
      Quick nudge: share your availability to start meeting nearby pals.
    </div>

    <div style="font-family: Arial, sans-serif; max-width:600px; margin:0 auto; padding:20px;">
      <div style="background:#ffffff; border-radius:12px; padding:24px; border:1px solid #eee;">
        <h1 style="color:#7c3aed; margin:0 0 12px;">We miss you, ${user.first_name || 'there'}! 🐾</h1>

        <p style="margin:0 0 12px; color:#1f2937;">
          It's been a bit since you joined ShareSkippy. The neighborhood has been wagging along without you, but it's not the same.
        </p>

        <p style="margin:16px 0 8px; color:#1f2937;">Here's what's new nearby:</p>
        <ul style="margin:0 0 16px 18px; padding:0; color:#374151;">
          <li>🐕 More pups and pals have joined</li>
          <li>📅 Fresh playtime availability each week</li>
          <li>💬 Neighbors are looking to connect</li>
        </ul>

        <p style="margin:16px 0; color:#1f2937;">
          Want to jump back in? The easiest way is to <strong>share your availability</strong> so neighbors know when you're free. That's how the real magic (and tail wags) start.
        </p>

        <div style="text-align:center; margin:28px 0;">
          <a href="${process.env.NEXT_PUBLIC_APP_URL || 'https://shareskippy.com'}/share-availability"
             style="background-color:#7c3aed; color:#ffffff !important; padding:14px 28px; text-decoration:none; border-radius:8px; display:inline-block; font-size:16px; font-weight:600;">
            Share Availability Now
          </a>
        </div>

        <!-- Light, fun closing (not cheesy) -->
        <p style="margin:0; color:#1f2937;">
          No barking — just a friendly tail wag. See you back in the pack soon!
        </p>

        <p style="margin:24px 0 0; font-size:14px; color:#6b7280;">— The ShareSkippy Team</p>
      </div>

      <!-- Footer (compliance & deliverability) -->
      <div style="text-align:center; color:#6b7280; font-size:12px; margin:16px 0;">
        <p style="margin:8px 0;">
          ShareSkippy · San Francisco, CA · United States
        </p>
        <p style="margin:8px 0;">
          <a href="${process.env.NEXT_PUBLIC_APP_URL || 'https://shareskippy.com'}/community" style="color:#7c3aed; text-decoration:none;">Community</a>
          &nbsp;•&nbsp;
          <a href="${process.env.NEXT_PUBLIC_APP_URL || 'https://shareskippy.com'}/share-availability" style="color:#7c3aed; text-decoration:none;">Share availability</a>
          &nbsp;•&nbsp;
          <a href="#" style="color:#7c3aed; text-decoration:none;">Unsubscribe</a>
        </p>
      </div>
    </div>
  </body>
</html>`,
          text: `We miss you, ${user.first_name || 'there'}! 🐾

It's been a bit since you joined ShareSkippy. The neighborhood has been wagging along without you, but it's not the same.

Here's what's new nearby:
🐕 More pups and pals have joined
📅 Fresh playtime availability each week
💬 Neighbors are looking to connect

Want to jump back in? The easiest way is to share your availability so neighbors know when you're free. That's how the real magic (and tail wags) start.

Share Availability Now: ${process.env.NEXT_PUBLIC_APP_URL || 'https://shareskippy.com'}/share-availability

Not here to bark— just wagging you back in!

— The ShareSkippy Team`
        });

        emailsSent++;

        // Track that re-engagement email was sent
        await supabase
          .from('user_settings')
          .upsert({
            user_id: user.id,
            re_engagement_email_sent: true,
            re_engagement_email_sent_at: new Date().toISOString()
          });

      } catch (error) {
        console.error(`Error sending re-engagement email to user ${user.id}:`, error);
        errors.push({
          userId: user.id,
          email: user.email,
          error: error.message
        });
      }
    }

    return Response.json({
      success: true,
      message: `Re-engagement emails processed`,
      emailsSent,
      usersProcessed: inactiveUsers?.length || 0,
      errors: errors.length > 0 ? errors : undefined
    });

  } catch (error) {
    console.error('Error in re-engagement emails:', error);
    return Response.json(
      { error: 'Failed to process re-engagement emails' }, 
      { status: 500 }
    );
  }
}
