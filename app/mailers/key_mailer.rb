class KeyMailer < ActionMailer::Base
    default from: "no-reply@virginia.edu"

    def key_email
       @key = params[:key]
       mail(to: @key.email, subject: 'Book Traces API Key')
     end
end
