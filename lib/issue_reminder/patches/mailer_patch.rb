module IssueReminder
  module Patches
    module MailerPatch
      def self.included(base)
        return if base < InstanceMethods
        base.class_eval do
          include InstanceMethods
        end
      end

      module InstanceMethods

        def issue_reminder(user, issues)
          set_language_if_valid user.language
          recipients user.mail
          issue_count = issues.values.inject(0){|sum, i| sum + i.size}
          subject l(:mail_subject_issue_reminder, :count => issue_count)
          body :issues => issues,
               :user => user,
               :issue_url => lambda{ |issue| url_for(:controller => 'issues', :action => 'show', :id => issue.id) }
          render_multipart('issue_reminder', body)
        end

      end
    end
  end
end
