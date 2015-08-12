shtmldir = $(datarootdir)/schulkonsole/shtml
dist_shtml_DATA = example.tt login.tt logout.tt start.tt \
	css.inc.tt dialog.inc.tt status.inc.tt \
	header.inc.tt footer.inc.tt footer_info.inc.tt \
	footer_submenu.inc.tt \
	room.tt room_handout.tt room_collect.tt room_shares.tt \
	room_test.tt room_test_end.tt \
	room_test_handout.tt room_test_password.tt room_test_collect.tt \
	room_end_lesson_verify.tt \
	class.tt class_list.tt class_passwords.tt showpassword.tt \
	class_handoutcopy.tt class_handout.tt class_collect.tt \
	class_shares.tt class_lesson.tt \
	project.tt project_members.tt project_addmembers.tt \
	project_handoutcopy.tt project_handout.tt project_collect.tt \
	project_shares.tt project_drop_verify.tt project_lesson.tt \
	project_passwords.tt \
	settings.tt settings_program.tt settings_users.tt \
	settings_classs.tt settings_projects.tt \
	user.tt user_students.tt user_teachers.tt user_extra.tt \
	user_teacherpasswords.tt \
	user_check.tt user_teachin.tt user_commit.tt user_reports.tt\
	rooms.tt rooms_classrooms.tt \
	printers.tt printers_edit.tt hosts.tt \
	quotas.tt \
	quotas_teachers.tt quotas_classes.tt quotas_projects.tt \
	quotas_others.tt \
	linbo.tt \
	linbo_edit.tt linbo_images.tt linbo_new.tt linbo_pxeedit.tt \
	linbo_regpatchedit.tt linbo_menuedit.tt \
	schulkonsole.js

CLEANFILES = messages.pl

messages.pl: $(dist_shtml_DATA)
	../bin/template-gettext.perl $(dist_shtml_DATA) > $@
