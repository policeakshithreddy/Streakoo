import os
import re

def replace_in_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Replace .withOpacity(x) with .withValues(alpha: x)
    # The regex handles simple cases. If there are nested parentheses it might be tricky, 
    # but usually opacity values are simple doubles or variables.
    new_content = re.sub(r'\.withOpacity\(([^)]+)\)', r'.withValues(alpha: \1)', content)
    
    if content != new_content:
        print(f"Updating {filepath}")
        with open(filepath, 'w') as f:
            f.write(new_content)

files = [
    'lib/screens/nav_wrapper.dart',
    'lib/screens/stats_screen.dart',
    'lib/screens/journal_screen.dart',
    'lib/screens/coach_screen.dart',
    'lib/screens/add_habit_screen.dart',
    'lib/screens/home_screen.dart',
    'lib/screens/challenge_selection_screen.dart',
    'lib/widgets/celebration_overlay.dart',
    'lib/widgets/achievement_banner.dart',
    'lib/widgets/streak_flame_graph.dart',
    'lib/widgets/level_badge.dart',
    'lib/widgets/mood_state_card.dart',
    'lib/widgets/streak_calendar.dart',
    'lib/widgets/mood_checkin_dialog.dart',
    'lib/widgets/progress_ring.dart',
    'lib/widgets/habit_heatmap.dart',
    'lib/widgets/habit_card.dart',
    'lib/widgets/category_radar_chart.dart'
]

for file in files:
    if os.path.exists(file):
        replace_in_file(file)
    else:
        print(f"File not found: {file}")
