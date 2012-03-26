module IssueReminder

  def self.deliver_issue_reminders
    inactive_issues.each_pair do |user, issues_by_project|
      Mailer.deliver_issue_reminder(user, issues_by_project)
    end
  end

  def self.deliver_due_issues
    due_issues.each_pair do |user, issues_by_project|
      Mailer.deliver_due_issues(user, issues_by_project)
    end
  end

  def self.close_old_resolved_issues
    # FIXME make the resolved / closed states configurable
    resolved = IssueStatus.find_by_name 'Gelöst'
    closed = IssueStatus.find_by_name 'Geschlossen'
    Issue.find(:all,
               :conditions => [
                 "updated_on < ? AND status_id = ?",
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

  # returns open issues that are
  # - not resolved
  # - belong to a project where the plugin has been activated
  # - have a due date smaller than now + 8 days
  def self.due_issues
    resolved = IssueStatus.find_by_name 'Gelöst'
    Hash.new{ |h,k|
      h[k] = Hash.new{ |h,k| h[k] = [] }
    }.tap do |issues_by_user_and_project|
      Issue.open.find(:all,
                      :joins => {:project => :enabled_modules},
                      :order => "#{Issue.table_name}.due_date ASC",
                      :conditions => [
                        "#{Issue.table_name}.status_id != ? AND #{Issue.table_name}.due_date IS NOT NULL AND #{Issue.table_name}.due_date < ? AND #{EnabledModule.table_name}.name = ? AND #{Project.table_name}.status = ?",
                        resolved.id,
                        8.days.from_now.beginning_of_day,
                        'issue_reminder',
                        Project::STATUS_ACTIVE
                      ]
                     ).each do |issue|
        users(issue.assigned_to).uniq.each do |receiver|
          if receiver.allowed_to?(:receive_due_issues, issue.project)
            issues_by_user_and_project[receiver][issue.project] << issue
          end
        end
      end
    end
  end

  def self.inactive_issues
    issues_by_user_and_project = {}
    Issue.open.find(:all,
                    :joins => {:project => :enabled_modules},
                    :conditions => [
                      "#{Issue.table_name}.updated_on < ? AND #{EnabledModule.table_name}.name = ? AND #{Project.table_name}.status = ?",
                      Setting.plugin_redmine_issue_reminder['remind_after_days'].to_i.days.ago,
                      'issue_reminder',
                      Project::STATUS_ACTIVE
                    ]).each do |issue|
      receivers = users(issue.assigned_to)
      receivers += other_receivers(issue.project, :receive_due_issues)
      receivers.uniq.each do |receiver|
        issues_by_project = issues_by_user_and_project[receiver] ||= {}
        (issues_by_project[issue.project] ||= []) << issue
      end
    end
    return issues_by_user_and_project
  end

  def self.other_receivers(project, permission)
    project.members.map(&:principal).select do |p|
      p.allowed_to?(permission, project)
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
