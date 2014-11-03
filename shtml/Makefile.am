shtmldir = $(datarootdir)/schulkonsole/shtml
dist_shtml_DATA = example.shtml login.shtml logout.shtml start.shtml \
	menu.shtml.inc status.shtml.inc \
	room.shtml room_handout.shtml room_collect.shtml room_shares.shtml \
	room_test.shtml room_test_end.shtml \
	room_test_handout.shtml room_test_password.shtml room_test_collect.shtml \
	room_end_lesson_verify.shtml \
	class.shtml class_list.shtml class_passwords.shtml showpassword.shtml \
	class_handoutcopy.shtml class_handout.shtml class_collect.shtml \
	class_shares.shtml \
	project.shtml project_members.shtml project_addmembers.shtml \
	project_handoutcopy.shtml project_handout.shtml project_collect.shtml \
	project_shares.shtml project_drop_verify.shtml \
	settings.shtml settings_program.shtml settings_users.shtml \
	settings_classs.shtml settings_backup.shtml \
	user.shtml user_students.shtml user_teachers.shtml user_extra.shtml \
	user_teacherpasswords.shtml \
	user_check.shtml user_teachin.shtml user_commit.shtml user_reports.shtml\
	rooms.shtml rooms_classrooms.shtml \
	printers.shtml printers_edit.shtml hosts.shtml \
	quotas.shtml \
	quotas_teachers.shtml quotas_classes.shtml quotas_projects.shtml \
	quotas_others.shtml \
	linbo.shtml \
	linbo_edit.shtml linbo_images.shtml linbo_new.shtml linbo_pxeedit.shtml \
	linbo_regpatchedit.shtml \
	submenu-room.shtml.inc submenu-class.shtml.inc \
	submenu-project.shtml.inc submenu-user.shtml.inc \
	submenu-settings.shtml.inc submenu-quotas.shtml.inc \
	submenu-rooms.shtml.inc subsubmenu-room_test.shtml.inc \
	submenu-linbo.shtml.inc \
	schulkonsole.js

CLEANFILES = messages.pl

messages.pl: $(dist_shtml_DATA)
	../bin/template-gettext.perl $(dist_shtml_DATA) > $@
