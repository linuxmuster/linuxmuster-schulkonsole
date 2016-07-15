#!/bin/bash
# /usr/share/schulkonsole/scripts/make-menus.sh
# erzeugt .inc.tt-Dateien aus menu*, submenu-xxx-*-Dateien
# durch sortierte Verkettung.
# Dateien in $MENUUSERDIR überstimmen Dateien aus $MENUDIR.
#
# Frank Schütte, 2015
#
MENUDIR=/usr/lib/schulkonsole/menus.d
MENUUSERDIR=/etc/linuxmuster/schulkonsole/menus.d
TTDIR=/usr/share/schulkonsole/tt
EXT=.inc.tt
MENU=menu
SUBMENU=submenu
SUBSUBMENU=subsubmenu

# create menu
FILES=$(find $MENUDIR $MENUUSERDIR -name "$MENU-*" -printf '%f\n'|sort -u)
TARGET=$TTDIR/$MENU$EXT
rm -f $TARGET
touch $TARGET
echo "Kopiere [$FILES] in $TARGET"|tr '\n' ' '
echo
for f in $FILES; do
  ff=$MENUDIR/$f
  [ -e $MENUUSERDIR/$f ] && ff=$MENUUSERDIR/$f
  cat $ff >>$TARGET
done;

# create submenus
MENUS=$(find $MENUDIR $MENUUSERDIR -name "$SUBMENU-*" -printf '%f\n'|perl -ne '/submenu-(\w+)-.*/&& print $1."\n"'|sort -u)
echo "Submenus: [$MENUS]"|tr '\n' ' '
echo
for s in $MENUS; do
  FILES=$(find $MENUDIR $MENUUSERDIR -name "$SUBMENU-$s-*" -printf '%f\n'|sort -u)
  TARGET=$TTDIR/$SUBMENU-$s$EXT
  rm -f $TARGET
  touch $TARGET
  echo "Kopiere [$FILES] in $TARGET"|tr '\n' ' '
  echo
  for f in $FILES; do
    ff=$MENUDIR/$f
    [ -e $MENUUSERDIR/$f ] && ff=$MENUUSERDIR/$f
    cat $ff >>$TARGET
  done;
done;

# create subsubmenus
MENUS=$(find $MENUDIR $MENUUSERDIR -name "$SUBSUBMENU-*" -printf '%f\n'|perl -ne '/subsubmenu-(\w+)-.*/&& print $1."\n"'|sort -u)
echo "Subsubmenus: [$MENUS]"|tr '\n' ' '
echo
for s in $MENUS; do
  FILES=$(find $MENUDIR $MENUUSERDIR -name "$SUBSUBMENU-$s-*" -printf '%f\n'|sort)
  TARGET=$TTDIR/$SUBSUBMENU-$s$EXT
  rm -f $TARGET
  touch $TARGET
  echo "Kopiere [$FILES] in $TARGET"|tr '\n' ' '
  echo
  for f in $FILES; do
    ff=$MENUDIR/$f
    [ -e $MENUUSERDIR/$f ] && ff=$MENUUSERDIR/$f
    cat $ff >>$TARGET
  done;
done;

exit 0;
