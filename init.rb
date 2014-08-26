# encoding: utf-8

require 'redmine'
require_dependency 'mailer'

def patch_class(clazz, patch)
  clazz.send(:include, patch) unless clazz.include?(patch)
end

Rails.configuration.to_prepare do
  patch_class Mailer, IssueReminder::Patches::MailerPatch
end


Redmine::Plugin.register :redmine_issue_reminder do
  name 'Inactive Issue Reminder'
  author 'Jens Krämer'
  description 'Notifications for issues that havent been updated for a configurable number of days'
  version '0.1.0'
  author_url 'http://jkraemer.net/'

  settings :default => {
    'remind_after_days' => '90',
    'close_issues_after_days' => '120'
  }, :partial => 'issue_reminder/settings'

  project_module :issue_reminder do
    permission :receive_issue_reminders, {}
    permission :receive_due_issues, {}
  end
end
