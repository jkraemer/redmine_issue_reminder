module IssueReminder

  def self.deliver_issue_reminders
    issues_for_delivery.each_pair do |user, issues_by_project|
      Mailer.deliver_issue_reminder(user, issues_by_project)
    end
  end

  def self.close_old_resolved_issues
    resolved = IssueStatus.find_by_name 'Gelöst'
    closed = IssueStatus.find_by_name 'Geschlossen'
    Issue.find(:all,
               :conditions => [
                 "updated_on < ? AND status_id = ?",
                 Setting.plugin_redmine_issue_reminder['close_issues_after_days'].to_i.days.ago,
                 resolved.id
               ]).each do |issue|
      i = Issue.find issue.id
      i.update_attribute :status, closed unless i.closed?
    end
  end

  private

  def self.issues_for_delivery
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
      receivers += other_receivers(issue.project)
      receivers.uniq.each do |receiver|
        issues_by_project = issues_by_user_and_project[receiver] ||= {}
        (issues_by_project[issue.project] ||= []) << issue
      end
    end
    return issues_by_user_and_project
  end

  def self.other_receivers(project)
    project.members.map(&:principal).select do |p|
      p.allowed_to?(:receive_issue_reminders, project)
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
