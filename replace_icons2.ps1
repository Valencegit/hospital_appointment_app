# Simple string replacement - much faster than regex
$replacements = @(
  @('Icons.arrow_back_rounded','BootstrapIcons.arrow_left'),
  @('Icons.arrow_back_ios_new_rounded','BootstrapIcons.arrow_left'),
  @('Icons.arrow_back_ios_new','BootstrapIcons.arrow_left'),
  @('Icons.arrow_forward_ios_rounded','BootstrapIcons.chevron_right'),
  @('Icons.chevron_left','BootstrapIcons.chevron_left'),
  @('Icons.chevron_right','BootstrapIcons.chevron_right'),
  @('Icons.email_outlined','BootstrapIcons.envelope'),
  @('Icons.lock_outline_rounded','BootstrapIcons.lock'),
  @('Icons.visibility_off_outlined','BootstrapIcons.eye_slash'),
  @('Icons.visibility_outlined','BootstrapIcons.eye'),
  @('Icons.person_outline_rounded','BootstrapIcons.person'),
  @('Icons.person_add_outlined','BootstrapIcons.person_add'),
  @('Icons.person_search_outlined','BootstrapIcons.person_lines_fill'),
  @('Icons.person_off_outlined','BootstrapIcons.person_dash'),
  @('Icons.admin_panel_settings_outlined','BootstrapIcons.shield_lock'),
  @('Icons.admin_panel_settings_rounded','BootstrapIcons.shield_lock_fill'),
  @('Icons.login_rounded','BootstrapIcons.box_arrow_in_right'),
  @('Icons.logout_rounded','BootstrapIcons.box_arrow_right'),
  @('Icons.logout','BootstrapIcons.box_arrow_right'),
  @('Icons.calendar_month_outlined','BootstrapIcons.calendar'),
  @('Icons.calendar_month_rounded','BootstrapIcons.calendar_fill'),
  @('Icons.calendar_today_outlined','BootstrapIcons.calendar_date'),
  @('Icons.calendar_today_rounded','BootstrapIcons.calendar_check'),
  @('Icons.calendar_today','BootstrapIcons.calendar_date'),
  @('Icons.date_range_outlined','BootstrapIcons.calendar_range'),
  @('Icons.access_time_outlined','BootstrapIcons.clock'),
  @('Icons.access_time_rounded','BootstrapIcons.clock_fill'),
  @('Icons.schedule_outlined','BootstrapIcons.clock'),
  @('Icons.event_note_outlined','BootstrapIcons.journal_text'),
  @('Icons.event_busy_outlined','BootstrapIcons.calendar_x'),
  @('Icons.local_hospital_outlined','BootstrapIcons.hospital'),
  @('Icons.local_hospital_rounded','BootstrapIcons.hospital_fill'),
  @('Icons.medical_services_outlined','BootstrapIcons.bag_plus'),
  @('Icons.health_and_safety_outlined','BootstrapIcons.shield_plus'),
  @('Icons.healing_outlined','BootstrapIcons.bandaid'),
  @('Icons.bloodtype_outlined','BootstrapIcons.droplet'),
  @('Icons.emergency_outlined','BootstrapIcons.exclamation_diamond'),
  @('Icons.biotech_outlined','BootstrapIcons.eyedropper'),
  @('Icons.psychology_outlined','BootstrapIcons.brain'),
  @('Icons.favorite_outlined','BootstrapIcons.heart'),
  @('Icons.favorite_rounded','BootstrapIcons.heart_fill'),
  @('Icons.pregnant_woman_outlined','BootstrapIcons.person_heart'),
  @('Icons.child_care_outlined','BootstrapIcons.emoji_smile'),
  @('Icons.face_outlined','BootstrapIcons.person_bounding_box'),
  @('Icons.hearing_outlined','BootstrapIcons.ear'),
  @('Icons.accessibility_new_outlined','BootstrapIcons.universal_access'),
  @('Icons.notifications_none_rounded','BootstrapIcons.bell'),
  @('Icons.notifications_rounded','BootstrapIcons.bell_fill'),
  @('Icons.check_circle_outline','BootstrapIcons.check_circle'),
  @('Icons.check_circle_rounded','BootstrapIcons.check_circle_fill'),
  @('Icons.check_rounded','BootstrapIcons.check_lg'),
  @('Icons.check_outlined','BootstrapIcons.check'),
  @('Icons.done_all_outlined','BootstrapIcons.check_all'),
  @('Icons.cancel_outlined','BootstrapIcons.x_circle'),
  @('Icons.close_rounded','BootstrapIcons.x_lg'),
  @('Icons.close','BootstrapIcons.x_lg'),
  @('Icons.error_outline_rounded','BootstrapIcons.exclamation_circle_fill'),
  @('Icons.error_outline','BootstrapIcons.exclamation_circle'),
  @('Icons.info_outline_rounded','BootstrapIcons.info_circle_fill'),
  @('Icons.info_outline','BootstrapIcons.info_circle'),
  @('Icons.info_rounded','BootstrapIcons.info_circle_fill'),
  @('Icons.block_outlined','BootstrapIcons.slash_circle'),
  @('Icons.settings_outlined','BootstrapIcons.gear'),
  @('Icons.home_filled','BootstrapIcons.house_fill'),
  @('Icons.search','BootstrapIcons.search'),
  @('Icons.add','BootstrapIcons.plus_lg'),
  @('Icons.edit_outlined','BootstrapIcons.pencil'),
  @('Icons.more_vert','BootstrapIcons.three_dots_vertical'),
  @('Icons.more_horiz_rounded','BootstrapIcons.three_dots'),
  @('Icons.assignment_outlined','BootstrapIcons.clipboard'),
  @('Icons.history_outlined','BootstrapIcons.clock_history'),
  @('Icons.insert_chart_outlined_rounded','BootstrapIcons.bar_chart'),
  @('Icons.hourglass_empty_outlined','BootstrapIcons.hourglass'),
  @('Icons.send_rounded','BootstrapIcons.send'),
  @('Icons.mark_email_read_rounded','BootstrapIcons.envelope_check'),
  @('Icons.swap_horiz_outlined','BootstrapIcons.arrow_left_right'),
  @('Icons.keyboard_arrow_down_rounded','BootstrapIcons.chevron_down'),
  @('Icons.phone_outlined','BootstrapIcons.telephone'),
  @('Icons.smartphone_outlined','BootstrapIcons.phone'),
  @('Icons.help_outline_rounded','BootstrapIcons.question_circle'),
  @('Icons.people_alt_rounded','BootstrapIcons.people_fill'),
  @('Icons.people_outline_rounded','BootstrapIcons.people'),
  @('Icons.people_outline','BootstrapIcons.people'),
  @('Icons.support_agent_outlined','BootstrapIcons.headset'),
  @('Icons.badge_outlined','BootstrapIcons.person_badge'),
  @('Icons.verified_rounded','BootstrapIcons.patch_check_fill'),
  @('Icons.verified_user_outlined','BootstrapIcons.shield_check'),
  @('Icons.security_rounded','BootstrapIcons.shield_fill'),
  @('Icons.apartment_outlined','BootstrapIcons.building'),
  @('Icons.apple','BootstrapIcons.apple'),
  @('Icons.g_mobiledata_rounded','BootstrapIcons.google')
)

$import = "import 'package:bootstrap_icons/bootstrap_icons.dart';"

$files = Get-ChildItem -Path lib -Recurse -Filter "*.dart" | Where-Object { (Get-Content $_.FullName -Raw) -match 'Icons\.' }

foreach ($file in $files) {
    $c = [System.IO.File]::ReadAllText($file.FullName)
    foreach ($r in $replacements) { $c = $c.Replace($r[0], $r[1]) }
    if ($c -notmatch 'bootstrap_icons') {
        # find position after last import
        $idx = 0; $lines = $c -split "`n"
        for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match "^import ") { $idx = $i } }
        $lines = $lines[0..$idx] + $import + $lines[($idx+1)..($lines.Count-1)]
        $c = $lines -join "`n"
    }
    [System.IO.File]::WriteAllText($file.FullName, $c)
    Write-Host $file.Name
}
Write-Host "Done"
