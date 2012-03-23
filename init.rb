require 'redmine'
require 'dispatcher'

def patch_class(clazz, patch)
  clazz.send(:include, patch) unless clazz.include?(patch)
end

Dispatcher.to_prepare do
  require_dependency 'issue_reminder/patches/mailer_patch'
  patch_class Mailer, IssueReminder::Patches::MailerPatch
end


Redmine::Plugin.register :redmine_issue_reminder do
  name 'Inactive Issue Reminder'
  author 'Jens Krämer'
  description 'Notifications for issues that havent been updated for a configurable number of days'
  version '0.0.1'
  author_url 'http://www.jkraemer.net/'

  settings :default => {
    'remind_after_days' => '90',
    'close_issues_after_days' => '120'
  }, :partial => 'issue_reminder/settings'

  project_module :issue_reminder do
    permission :receive_issue_reminders, {}
  end
end
