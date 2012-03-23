namespace :redmine do

  desc <<-END_DESC
  Send out notifications on inactive issues.
  Example:
     RAILS_ENV="production" rake redmine:send_issue_reminders
  END_DESC
  task :send_issue_reminders => :environment do
    require 'issue_reminder'
    IssueReminder.deliver_issue_reminders
  end

  desc <<-END_DESC
  Close issues that are resolved and unchanged since more than 120 days.
  Example:
     RAILS_ENV="production" rake redmine:close_old_resolved_issues
  END_DESC
  task :close_old_resolved_issues => :environment do
    require 'issue_reminder'
    IssueReminder.close_old_resolved_issues
  end

end
