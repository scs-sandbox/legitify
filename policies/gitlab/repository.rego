package repository

# METADATA
# scope: rule
# title: Project Should Be Updated At Least Quarterly
# description: A project which is not actively maintained may not be patched against security issues within its code and dependencies, and is therefore at higher risk of including known vulnerabilities.
# custom:
#   remediationSteps: [Make sure you have admin permissions, Either Delete or Archive the project]
#   severity: HIGH
#   threat: As new vulnerabilities are found over time, unmaintained repositories are more likely to point to dependencies that have known vulnerabilities, exposing these repositories to 1-day attacks.
default project_not_maintained = true

project_not_maintained = false {
	input.archived == false
	ns := time.parse_rfc3339_ns(input.last_activity_at)
	now := time.now_ns()
	diff := time.diff(now, ns)
	monthsIndex := 1
	inactivityMonthsThreshold := 3
	diff[monthsIndex] < inactivityMonthsThreshold
	yearIndex := 0
	diff[yearIndex] == 0
}

# METADATA
# scope: rule
# title: Project Should Have Fewer Than Three Owners
# description: Projects owners are highly privileged and could create great damage if they are compromised. It is recommeneded to limit the number of Project OWners to the minimum required (recommended maximum 3 admins).
# custom:
#   severity: LOW
#   remediationSteps: [Make sure you have owner permissions, Go to the Project Information -> Members page, Select the unwanted owner users and remove the selected owners]
#   threat:
#     - "A compromised user with owner permissions can initiate a supply chain attack in a plethora of ways."
#     - "Having many admin users increases the overall risk of user compromise, and makes it more likely to lose track of unused admin permissions given to users in the past."
default project_has_too_many_admins = true

project_has_too_many_admins = false {
	admins := [admin | admin := input.members[_]; admin.access_level == 50]
	count(admins) <= 3
}

# METADATA
# scope: rule
# title: Forking Should Not Be Allowed
# description: Forking a repository can lead to loss of control and potential exposure of source code. If you do not need forking, it is recommended to turn it off in the project's configuration. The option to fork should be enabled only by owners deliberately when opting to create a fork.
# custom:
#   remediationSteps: [Make sure you have owner permissions, Go to the project's settings page, Enter "General" tab, Under "Visibility, project features, permissions", Toggle off "Forks"]
#   severity: LOW
#   threat: Forked repositories may leak important code assets or sensitive secrets embedded in the code to anyone outside your organization, as the code becomes publicy-accessible
default forking_allowed_for_repository = true

forking_allowed_for_repository = false {
	input.public
}

forking_allowed_for_repository = false {
	not input.public
	input.forking_access_level != "enabled"
}

# METADATA
# scope: rule
# title: Default Branch Should Be Protected
# description: Branch protection is not enabled for this repository’s default branch. Protecting branches ensures new code changes must go through a controlled merge process and allows enforcement of code review as well as other security tests. This issue is raised if the default branch protection is turned off.
# custom:
#   remediationSteps: [Make sure you have owner permissions, Go to the projects's settings -> Repository page, Enter "Protected branches" tab, select the default branch. Set the allowed to merge to "maintainers" and the allowed to push to "No one"]
#   severity: MEDIUM
#   threat: Any contributor with write access may push potentially dangerous code to this repository, making it easier to compromise and difficult to audit.
default missing_default_branch_protection = true

missing_default_branch_protection = false {
	default_protected_branches := [protected_branch | protected_branch := input.protected_branches[_]; protected_branch.name == input.default_branch]
	count(default_protected_branches) > 0
}

# METADATA
# scope: rule
# title: Default Branch Should Not Allow Force Pushes
# description: The history of the default branch is not protected against changes for this repository. Protecting branch history ensures every change that was made to code can be retained and later examined. This issue is raised if the default branch history can be modified using force push.
# custom:
#   remediationSteps: [Make sure you have owner permissions, Go to the projects's settings -> Repository page, Enter "Protected branches" tab, select the default branch. Set the allowed to merge to "maintainers" and the allowed to push to "No one"]
#   severity: MEDIUM
#   threat: Rewriting project history can make it difficult to trace back when bugs or security issues were introduced, making them more difficult to remediate.
default missing_default_branch_protection_force_push = true

missing_default_branch_protection_force_push = false {
	
    default_protected_branches := [protected_branch | protected_branch := input.protected_branches[_]; protected_branch.name == input.default_branch]
	count(default_protected_branches) > 0
	rules_allow_force_push := [rule_allow_force_push | rule_allow_force_push := default_protected_branches[_]; rule_allow_force_push.allow_force_push == true]
	count(rules_allow_force_push) == 0
}

# METADATA
# scope: rule
# title: Default Branch Should Limit Code Review to Code-Owners
# description: It is recommended to require code review only from designated individuals specified in CODEOWNERS file. Turning this option on enforces that only the allowed owners can approve a code change. This option is found in the branch protection setting of the project.
# custom:
#   remediationSteps: [Make sure you have owner permissions, Go to the projects's settings -> Repository page, Enter "Protected branches" tab, select the default branch. Check the "Code owner approval"]
#   severity: LOW
#   threat: A pull request may be approved by any contributor with write access. Specifying specific code owners can ensure review is only done by individuals with the correct expertise required for the review of the changed files, potentially preventing bugs and security risks.
default repository_require_code_owner_reviews_policy = true

repository_require_code_owner_reviews_policy = false {
	
	default_protected_branches := [protected_branch | protected_branch := input.protected_branches[_]; protected_branch.name == input.default_branch]
	rules_allow_force_push := [ rule_require_code_owner_review | rule_require_code_owner_review := default_protected_branches[_]; rule_require_code_owner_review.code_owner_approval_required ]
	count(rules_allow_force_push) > 0
}

# METADATA
# scope: rule
# title: Webhook Configured Without SSL Verification
# description: Webhooks that are not configured with SSL verification enabled could expose your sofware to man in the middle attacks (MITM).
# custom:
#   severity: LOW
#   remediationSteps: [Make sure you can manage webhooks for the project, Go to the project's settings page, Select "Webhooks", Press on the "Enable SSL verfication", Click "Save changes"]
#   threat:
#     - "If SSL verification is disabled, any party with access to the target DNS domain can masquerade as your designated payload URL, allowing it freely read and affect the response of any webhook request."
#     - "In the case of GitLab Self-Managed, it may be sufficient only to control the DNS configuration of the network where the instance is deployed, as an attacker can redirect traffic to the target domain in your internal network directly to them, and this is often much easier than compromising an internet-facing domain."
default project_webhook_doesnt_require_ssl = true

project_webhook_doesnt_require_ssl = false{
	webhooks_without_ssl_verification := [webhook_without_verification | webhook_without_verification := input.webhooks[_]; webhook_without_verification.enable_ssl_verification == false]
	count(webhooks_without_ssl_verification) == 0
}

# METADATA
# scope: rule
# title: Project Should Require All Pipelines to Succeed
# description: Checks that validate the quality and security of the code are not required to pass before submitting new changes. It is advised to turn this flag on to ensure any existing or future check will be required to pass.
# custom:
#   severity: MEDIUM
#   remediationSteps: [Make sure you can manage project merge requests permissions, Go to the project's settings page, Select "Merge Requests", Press on the "Pipelines must succeed", Click "Save changes"]
#   threat: Not defining a set of required status checks can make it easy for contributors to introduce buggy or insecure code as manual review, whether mandated or optional, is the only line of defense.
default requires_status_checks = true

requires_status_checks = false {
	input.only_allow_merge_if_pipeline_succeeds
}

# METADATA
# scope: rule
# title: Project Should Require All Conversations To Be Resolved Before Merge
# description: Require all merge request conversations to be resolved before merging. Check this to avoid bypassing/missing a Pull Reuqest comment.
# custom:
#   severity: LOW
#   remediationSteps: [Make sure you can manage project merge requests permissions, Go to the project's settings page, Select "Merge Requests", Press on the "All threads must be resolved", Click "Save changes"]
#   threat: Allowing the merging of code without resolving all conversations can promote poor and vulnerable code, as important comments may be forgotten or deliberately ignored when the code is merged.
default no_conversation_resolution = true

no_conversation_resolution = false {
	input.only_allow_merge_if_all_discussions_are_resolved
}

# METADATA
# scope: rule
# title: Default Branch Should Require All Commits To Be Signed
# description: Require all commits to be signed and verified
# custom:
#   remediationSteps: [Make sure you have owner permissions, Go to the projects's settings -> Repository page, Enter "Push Rules" tab. Set the "Reject unsigned commits" checkbox ]
#   severity: LOW
#   threat: A commit containing malicious code may be crafted by a malicious actor that has acquired write access to the repository to initiate a supply chain attack. Commit signing provides another layer of defense that can prevent this type of compromise.
default no_signed_commits = true

no_signed_commits = false {
	input.push_rules.reject_unsigned_commits
}


# METADATA
# scope: rule
# title: Default Branch Should Require Code Review
# description: In order to comply with separation of duties principle and enforce secure code practices, a code review should be mandatory using the source-code-management built-in enforcement.
# custom:
#   remediationSteps: [Make sure you have admin permissions, Go to the repo's settings page, Enter "Merge Requests" tab, Under "Merge request approvals", Click "Add approval rule" on the default branch rule, Select "Approvals required" and enter at least 1 approvers", Select "Add approvers" and select the desired members, Click "Add approval rule"]
#   severity: HIGH
#   threat:
#    - "Users can merge code without being reviewed which can lead to insecure code reaching the main branch and production."
default code_review_not_required = true

code_review_not_required = false {
	input.minimum_required_approvals >= 1
}

# METADATA
# scope: rule
# title: Default Branch Should Require Code Review By At Least Two Reviewers
# description: In order to comply with separation of duties principle and enforce secure code practices, a code review should be mandatory using the source-code-management built-in enforcement.
# custom:
#   remediationSteps: [Make sure you have admin permissions, Go to the repo's settings page, Enter "Merge Requests" tab, Under "Merge request approvals", Click "Add approval rule" on the default branch rule, Select "Approvals required" and enter at least 2 approvers", Select "Add approvers" and select the desired members, Click "Add approval rule"]
#   severity: MEDIUM
#   threat:
#    - "Users can merge code without being reviewed which can lead to insecure code reaching the main branch and production."
default code_review_by_two_members_not_required = true

code_review_by_two_members_not_required = false {
	input.minimum_required_approvals >= 2
}

# METADATA
# scope: rule
# title: Repository Should Not Allow Review Requester To Approve Their Own Request
# description: To comply with separation of duties and enforce secure code practices, the repository should prohibit pull request owners from approving their own changes.
# custom:
#   remediationSteps: [Make sure you have admin permissions, Go to the repo's settings page, Enter "Merge Requests" tab, Under "Approval settings", Check "Prevent approval by author", Click "Save Changes"]
#   severity: MEDIUM
#   threat:
#    - "Users can merge code without being reviewed which can lead to insecure code reaching the main branch and production."
default repository_allows_review_requester_to_approve_their_own_request = true

repository_allows_review_requester_to_approve_their_own_request = false {
	not input.approval_configuration.merge_requests_author_approval
}

# METADATA
# scope: rule
# title: Merge Request Authors Should Not Be Able To Override the Approvers List
# description: A repository should not allow merge request authors to freely edit the list of required approvers. To enforce code review only by authorized personnel, the option to override the list of valid approvers for the merge request must be toggled off.
# custom:
#   remediationSteps: [Make sure you have admin permissions, Go to the repo's settings page, Enter "Merge Requests" tab, Under "Approval settings", Check "Prevent editing approval rules in merge requests", Click "Save Changes"]
#   severity: MEDIUM
#   threat:
#    - "Users can merge code without being reviewed which can lead to insecure code reaching the main branch and production."
default repository_allows_overriding_approvers = true

repository_allows_overriding_approvers = false {
	input.approval_configuration.disable_overriding_approvers_per_merge_request 
}

# METADATA
# scope: rule
# title: Repository Should Not Allow Committer Approvals
# description: The repository allows merge request contributors (that aren't the merge request author), to approve the merge request. To ensure merge request review is done objectively, it is recommended to toggle this option off.
# custom:
#   remediationSteps: [Make sure you have admin permissions, Go to the repo's settings page, Enter "Merge Requests" tab, Under "Approval settings", Check "Prevent approvals by users who add commits", Click "Save Changes"]
#   severity: LOW
#   threat:
#    - "Users can merge code without being reviewed which can lead to insecure code reaching the main branch and production."
default repository_allows_committer_approvals_policy = true

repository_allows_committer_approvals_policy = false {
	input.approval_configuration.merge_requests_disable_committers_approval
}

# METADATA
# scope: rule
# title: Default Branch Should Require New Code Changes After Approval To Be Re-Approved
# description: This security control prevents merging code that was approved but later on changed. Turning it on ensures new changes are required to be reviewed again. This setting is part of the Merge request approval settings, and hardens the code-review process. If turned off - a developer can change the code after approval, and push code that is different from the one that was previously allowed.
# custom:
#   remediationSteps: [Make sure you have admin permissions, Go to the repo's settings page, Enter "Merge Requests" tab, Under "Approval settings", Check "Remove all approvals", Click "Save Changes"]
#   severity: LOW
#   threat: Buggy or insecure code may be committed after approval and will reach the main branch without review. Alternatively, an attacker can attempt a just-in-time attack to introduce dangerous code just before merge.
default repository_dismiss_stale_reviews = true

repository_dismiss_stale_reviews = false {
	input.approval_configuration.reset_approvals_on_push
}
