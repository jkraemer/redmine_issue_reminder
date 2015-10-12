require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper')

class IssueReminderTest < ActiveSupport::TestCase
  if Redmine::VERSION::MAJOR < 3
    fixtures :projects, :enabled_modules, :issues, :users,
      :members, :member_roles, :roles, :trackers, :projects_trackers,
      :issue_statuses, :enumerations, :journals
  else
    fixtures :projects, :enabled_modules, :issues, :users, :email_addresses,
      :members, :member_roles, :roles, :trackers, :projects_trackers,
      :issue_statuses, :enumerations, :journals
  end

  setup do
    (@emails = ActionMailer::Base.deliveries).clear
    Setting.plugin_redmine_issue_reminder['resolved_state_id'] = '3'
    Setting.plugin_redmine_issue_reminder['closed_state_id'] = '5'
    Setting.plugin_redmine_issue_reminder['remind_after_days'] = '90'
    @project = Project.find 1
    EnabledModule.create! project_id: 1, name: 'issue_reminder'
    Role.find(2).tap do |r|
      r.permissions << :receive_due_issues
      r.save
    end
  end

  test 'should have resolved and closed states' do
    assert_equal 3, IssueReminder.send(:resolved_state).id
    assert_equal 5, IssueReminder.send(:closed_state).id
  end


  test 'should close old resolved issues' do
  end

  test 'should find due issues' do
    assert issues_by_user_and_project = IssueReminder.send(:due_issues)
    assert_equal 1, issues_by_user_and_project.size
    assert user = issues_by_user_and_project.keys.first
    assert_equal 3, user.id
    assert issues_by_project = issues_by_user_and_project[user]
    assert_equal 1, issues_by_project.size
    assert project = issues_by_project.keys.first
    assert_equal 1, project.id
    assert issues = issues_by_project[project]
    assert_equal 1, issues.size
    assert_equal 3, issues.first.id
  end

  test 'should send due issue reminders' do
    IssueReminder.deliver_due_issues
    assert_equal 1, @emails.size
  end

  test 'should find inactive issues' do
    assert inactive_issues_by_user = IssueReminder.send(:inactive_issues)
    assert_equal 1, inactive_issues_by_user.size
    assert u = inactive_issues_by_user.keys[0]
    assert_equal 3, u.id
    assert issues_by_project = inactive_issues_by_user[u]
    assert_equal 1, issues_by_project.size
    assert p = issues_by_project.keys[0]
    assert issues = issues_by_project[p]
    assert_equal 2, issues.size
    assert_equal p, issues[0].project
    issues.each {|i| assert_equal u, i.assigned_to}

    Role.find(1).tap do |r|
      r.permissions << :receive_issue_reminders
    end.save

    assert inactive_issues_by_user = IssueReminder.send(:inactive_issues)
    assert_equal 2, inactive_issues_by_user.size
  end

  test 'should only send inactive issue reminders to people having the permission' do
    IssueReminder.deliver_issue_reminders
    assert_equal 1, @emails.size
    @emails.clear

    Role.find(1).tap do |r|
      r.permissions << :receive_issue_reminders
    end.save

    IssueReminder.deliver_issue_reminders
    assert_equal 2, @emails.size
  end


end
