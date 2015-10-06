Redmine Issue Reminders
=======================

This plugin supplies several rake tasks for sending out email reminders
listing inactive issues, due / overdue issues, and for automatically
closing issues that have been marked 'resolved' a number of days ago and
not seen any activity since.

The email functionality has to be activated per project (Settings / Modules).
The closing of old resolved issues acts globally on all projects. Before using
the plugin for the first time you have to set the issue statuses to consider as
'resolved' and 'closed' in the global plugin settings (Administration /
Plugins).

Other configuration options are the number of days without activity after which
to consider an issue inactive (defaults to 90), and the number of days after
which to close resolved issues (defaults to 120).


inactive issue reminder
-----------------------

    rake redmine:send_issue_reminders

This task will send out one email to every user, listing all inactive
issues assigned to that user. In addition, if the user has the
permission _Receive inactive issue reminders (for the whole project)_ in
a given project, also inactive issues not assigned to that user will be
added to the list. Users not having any inactive issues wont receive an
email of course. The idea is to run this task once a week, i.e. on
sunday or monday morning in order to remind every user of his inactive
issues, and to give project managers (via the permission mentioned
above) an overview of inactive issues for their projects, regardless of
who's the assignee.


due issues reminder
-------------------

    rake redmine:send_due_issues

Sends out one email to users, reminding them of their unresolved issues
with a due date on or before (today + 7 days). So if this is run every
week on monday morning, every user will receive a list of issues that
are due this week or on next monday. The permission _Receive due and
overdue issue reminders (only if assignee)_ determines wether a user
will receive such notifications or not.

_Unresolved issues_ here are defined as 'not open' and not having the
resolved but open issue state as explained below. You might want to
customize that in lib/issue\_reminders.rb.


close old resolved issues
-------------------------

    rake redmine:close_old_resolved_issues

In our setup, we have a 'resolved' issue state which is not 'closed' in
the redmine sense. This is because in our workflow, an issue is
considered open until the customer (or whoever is the product owner)
actively sets the resolved issue to 'closed'. Sometimes however people
forget about this or feel too busy/lazy to do so. This rake task will
clean up such old resolved issues by auto-closing them. By doing so the
regular redmine email notifications will be sent out, reminding
everybody concerned with the issue one last time. Run this via cron i.e.
once a week. Be aware of the fact that if you have a lot of old resolved
but not closed issues, the first run might take a while, sending out a
lot of emails.


Supported Redmine versions
--------------------------

Current master should run on any Redmine 2.x. See the redmine-1.x tag for a version that runs on Redmine 1.2 - 1.4.

Bug reports and reports of success and failure
with other versions of Redmine are welcome of course.

License
-------

Copyright (C) 2012-2015 [Jens Krämer](https://jkraemer.net)

The Issue Reminders plugin for Redmine is free software: you can redistribute
it and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The Issue Reminders plugin for Redmine is distributed in the hope that it
will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
the plugin. If not, see [www.gnu.org/licenses](http://www.gnu.org/licenses/).

