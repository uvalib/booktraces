class KeyMailer < ActionMailer::Base
    default from: "booktraces.noreply@virginia.edu"

    def key_email
       @key = params[:key]
       mail(to: @key.email, subject: 'Book Traces API Key')
     end
end
