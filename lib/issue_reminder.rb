# encoding: utf-8
module IssueReminder

  def self.deliver_issue_reminders
    inactive_issues.each_pair do |user, issues_by_project|
      Mailer.issue_reminder(user, issues_by_project).deliver
    end
  end

  def self.deliver_due_issues
    due_issues.each_pair do |user, issues_by_project|
      Mailer.due_issues(user, issues_by_project).deliver
    end
  end

  def self.close_old_resolved_issues
    resolved = resolved_state
    closed = closed_state
    Issue.where([ "updated_on < ? AND status_id = ?",
                 Setting.plugin_redmine_issue_reminder['close_issues_after_days'].to_i.days.ago,
                 resolved.id
               ]).each do |issue|
      # closing parent issues closes child issues, too.
      # that may lead to stale, already closed issues in our list.
      i = Issue.find issue.id
      next if i.closed?
      i.init_journal(User.anonymous, "automatic close after #{Setting.plugin_redmine_issue_reminder['close_issues_after_days']} days")
      i.update_attribute :status, closed
    end
  end

  private

  def self.resolved_state
    IssueStatus.find Setting.plugin_redmine_issue_reminder['resolved_state_id']
  rescue ActiveRecord::RecordNotFound
    raise "'Resolved' state not found. Please configure the plugin before using it!"
  end

  def self.closed_state
    IssueStatus.find Setting.plugin_redmine_issue_reminder['closed_state_id']
  rescue ActiveRecord::RecordNotFound
    raise "'Closed' state not found. Please configure the plugin before using it!"
  end

  # returns open issues that are
  # - not resolved
  # - belong to a project where the plugin has been activated
  # - have a due date smaller than now + 8 days
  def self.due_issues
    resolved = resolved_state
    Hash.new{ |h,k|
      h[k] = Hash.new{ |h,k| h[k] = [] }
    }.tap do |issues_by_user_and_project|
      Issue.open.
        joins(:project => :enabled_modules).
        order("#{Issue.table_name}.due_date ASC").
        where([ "#{Issue.table_name}.status_id != ? AND #{Issue.table_name}.due_date IS NOT NULL AND #{Issue.table_name}.due_date < ? AND #{EnabledModule.table_name}.name = ? AND #{Project.table_name}.status = ?",
                resolved.id,
                8.days.from_now.beginning_of_day,
                'issue_reminder',
                Project::STATUS_ACTIVE
              ]).
        each do |issue|
          users(issue.assigned_to).uniq.each do |receiver|
            if non_admin_allowed_to?(receiver, issue.project, :receive_due_issues)
              issues_by_user_and_project[receiver][issue.project] << issue
            end
          end
        end
    end
  end

  # same as user#allowed_to, but only checking actual permissions, ignoring the result of user#admin?
  def self.non_admin_allowed_to?(user, project, permission)
    if roles = user.roles_for_project(project)
      return true if roles.detect {|role|
        role.member? && role.allowed_to?(permission)
      }
    end
  end

  def self.inactive_issues
    issues_by_user_and_project = {}
    Issue.open.
      joins(:project => :enabled_modules).
      where([ "#{Issue.table_name}.updated_on < ? AND #{EnabledModule.table_name}.name = ? AND #{Project.table_name}.status = ?",
              Setting.plugin_redmine_issue_reminder['remind_after_days'].to_i.days.ago,
              'issue_reminder',
              Project::STATUS_ACTIVE
            ]).
      each do |issue|
        receivers = users(issue.assigned_to)
        receivers += other_receivers(issue.project, :receive_issue_reminders)
        receivers.uniq.each do |receiver|
          issues_by_project = issues_by_user_and_project[receiver] ||= {}
          (issues_by_project[issue.project] ||= []) << issue
        end
    end
    return issues_by_user_and_project
  end

  def self.other_receivers(project, permission)
    project.members.map(&:principal).select do |p|
      non_admin_allowed_to?(p, project, permission)
    end.map do |p|
      users(p)
    end.flatten
  end

  def self.users(principal)
    if principal
      User === principal ? [principal] : principal.users.to_a
    else
      []
    end
  end

end
