module IssueReminder
  module Patches
    module MailerPatch

      def due_issues(user, issues)
        #set_language_if_valid user.language
        #issue_count = issues.values.inject(0){|sum, i| sum + i.size}
        #@issues = issues
        #@user = user
        #mail to: user.mail,
        #  subject: l(:mail_subject_due_issues, :count => issue_count)
        reminder_mail user, issues, :mail_subject_due_issues
      end

      def issue_reminder(user, issues)
        reminder_mail user, issues, :mail_subject_issue_reminder
      end

      def reminder_mail(user, issues, subject)
        set_language_if_valid user.language
        issue_count = issues.values.inject(0){|sum, i| sum + i.size}
        @issues = issues
        @user = user
        mail to: user.mail,
          subject: l(subject, count: issue_count)
      end
      private :reminder_mail

    end
  end
end
