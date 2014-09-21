pkglibexecdir = $(libexecdir)/@PACKAGE@/cgi-bin
pkglibexec_SCRIPTS=example start logout \
	room room_shares room_handout room_collect \
	room_test room_test_handout room_test_password room_test_collect \
	room_test_end \
	class class_list class_passwords class_collect class_handoutcopy \
	class_handout class_shares \
	project project_members project_addmembers project_handoutcopy \
	project_handout project_collect project_shares \
	settings \
	settings_program settings_users settings_classs settings_backup \
	user user_students user_teachers user_extra \
	user_teacherpasswords \
	user_check user_teachin user_commit user_reports \
	rooms rooms_classrooms \
	printers printers_edit hosts \
	quotas quotas_teachers quotas_classes quotas_projects quotas_others \
	linbo linbo_edit linbo_new linbo_regpatchedit linbo_pxeedit linbo_images \
	group_lesson project_lesson

CLEANFILES = $(pkglibexec_SCRIPTS)
EXTRA_DIST = example.in start.in logout.in \
	room.in room_shares.in room_handout.in room_collect.in room_test.in \
	room_test_handout.in room_test_password.in room_test_collect.in \
	room_test_end.in \
	class.in class_list.in class_passwords.in class_collect.in \
	class_handoutcopy.in class_handout.in class_shares.in \
	project.in project_members.in project_addmembers.in \
	project_handoutcopy.in project_handout.in project_collect.in \
	project_shares.in \
	settings.in settings_program.in settings_users.in settings_classs.in \
	settings_backup.in \
	user.in user_students.in user_teachers.in user_extra.in \
	user_teacherpasswords.in \
	user_check.in user_teachin.in user_commit.in user_reports.in \
	rooms.in rooms_classrooms.in \
	printers.in printers_edit.in hosts.in \
	quotas.in \
	quotas_teachers.in quotas_classes.in quotas_projects.in quotas_others.in \
	linbo.in linbo_edit.in linbo_new.in linbo_regpatchedit.in \
	linbo_pxeedit.in linbo_images.in \
	group_lesson.in project_lesson.in


do_subst = sed \
  -e 's,\@PACKAGE\@,$(PACKAGE),g' \
  -e 's,\@datadir\@,$(datadir),g'




%: %.in
	$(do_subst) $(srcdir)/$@.in > $@

