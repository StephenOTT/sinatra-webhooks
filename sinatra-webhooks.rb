# Generate a secret: ruby -rsecurerandom -e 'puts SecureRandom.hex(30)'
# Define env variable: export GITHUB_WEBHOOK_SECRET=your_secret
# Use the same secret in the GitHub Webhook configuration page

require 'sinatra'
require 'json'

# check that the environment variables are set
if ENV['GITHUB_WEBHOOK_SECRET'].nil?
    puts "The environment variable GITHUB_WEBHOOK_SECRET is undefined."
    exit
end

post '/webhook' do
    request.body.rewind                     # good practice for StringIO objects
    payload_body = request.body.read        # read it into a regular string
    verify_signature(payload_body)          # verify the payload as a string
    payload_hash = JSON.parse(payload_body) # convert JSON string to hash

    # Report a successful configuration if it's a ping event
    if request.env['HTTP_X_GITHUB_EVENT'] == "ping"
        return "Ping event received for repository: " +
               payload_hash["repository"]["full_name"] +
               ".\nThe webhook configuration appears to be correct."
    elsif request.env['HTTP_X_GITHUB_EVENT'] == "push"
        # Pull update from GitHub and then rebuild Middleman project
        cmd_ret  = "Executing: git pull\n" + %x[git pull] + "\n"
        cmd_ret += "Executing: bundle exec middleman build\n" +
                   %x[bundle exec middleman build]
        return cmd_ret
    else # unsupported event (HTTP code 400 = Bad Request)
        return halt 400, "Unsupported webhook event."
    end
end


def verify_signature(payload_body)
    # calculate the HMAC-SHA1 signature of the payload_body
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new('sha1'),
        ENV['GITHUB_WEBHOOK_SECRET'],
        payload_body)

    # check if a signature was included in the HTTP header
    if request.env['HTTP_X_HUB_SIGNATURE'].nil?
        # HTTP code 412 = Precondition Failed
        return halt 412, "A signature is required."
    else
        # perform a constant-time compare that protects against timing attacks
        if !Rack::Utils.secure_compare(
                signature,
                request.env['HTTP_X_HUB_SIGNATURE'])
            # HTTP code 401 = Unauthorized
            return halt 401, "The signature did not match! " +
                "Please ensure that the correct secret is being used."
        end
    end
end
