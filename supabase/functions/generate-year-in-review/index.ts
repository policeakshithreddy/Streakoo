import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Interface definitions
interface Habit {
  id: string
  user_id: string
  name: string
  emoji: string
  completion_dates: string[]
  xp_value: number
}

interface YearInReviewData {
  total_completions: number
  longest_streak: number
  most_consistent_habit: string
  most_consistent_emoji: string
  total_xp: number
  best_month: string
  avg_completion_rate: number
  habit_breakdown: Record<string, number>
  total_days_active: number
  perfect_days: number
}

serve(async (req) => {
  try {
    // Parse request body
    const { year } = await req.json()

    if (!year || typeof year !== 'number') {
      return new Response(
        JSON.stringify({ error: 'Year is required and must be a number' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Get user from JWT
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Create Supabase client with service role for database access
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        global: {
          headers: { Authorization: authHeader },
        },
      }
    )

    // Get authenticated user
    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser()

    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    console.log(`📊 Generating Year in Review for user ${user.id}, year ${year}`)

    // Fetch user's habits
    const { data: habits, error: habitsError } = await supabaseClient
      .from('habits')
      .select('*')
      .eq('user_id', user.id)

    if (habitsError) {
      throw habitsError
    }

    if (!habits || habits.length === 0) {
      return new Response(
        JSON.stringify({ error: 'No habits found for user' }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Calculate Year in Review statistics
    const reviewData = calculateYearInReview(habits as Habit[], year)

    // Check if review already exists
    const { data: existingReview } = await supabaseClient
      .from('year_in_review')
      .select('id')
      .eq('user_id', user.id)
      .eq('year', year)
      .maybeSingle()

    // Insert or update the review
    if (existingReview) {
      // Update existing
      const { error: updateError } = await supabaseClient
        .from('year_in_review')
        .update({
          ...reviewData,
          year,
          user_id: user.id,
        })
        .eq('id', existingReview.id)

      if (updateError) throw updateError
      console.log('✅ Updated existing Year in Review')
    } else {
      // Insert new
      const { error: insertError } = await supabaseClient
        .from('year_in_review')
        .insert({
          ...reviewData,
          year,
          user_id: user.id,
        })

      if (insertError) throw insertError
      console.log('✅ Created new Year in Review')
    }

    return new Response(
      JSON.stringify({ success: true, data: reviewData }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('❌ Error generating Year in Review:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

/**
 * Calculate Year in Review statistics from habits
 */
function calculateYearInReview(habits: Habit[], year: number): YearInReviewData {
  const yearStart = new Date(year, 0, 1)
  const yearEnd = new Date(year, 11, 31, 23, 59, 59)

  let totalCompletions = 0
  let longestStreak = 0
  let totalXP = 0
  const habitBreakdown: Record<string, number> = {}
  const monthlyCompletions: Record<string, number> = {}
  const activeDays = new Set<string>()
  const dailyCompletionCount: Record<string, number> = {}

  const monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ]

  for (const habit of habits) {
    let habitCompletions = 0

    // Count completions in this year
    for (const dateStr of habit.completion_dates || []) {
      try {
        const date = new Date(dateStr)
        if (date >= yearStart && date <= yearEnd) {
          habitCompletions++
          totalCompletions++
          totalXP += habit.xp_value || 10

          // Track active days
          const dayKey = dateStr.substring(0, 10) // YYYY-MM-DD
          activeDays.add(dayKey)

          // Track daily completion count
          dailyCompletionCount[dayKey] = (dailyCompletionCount[dayKey] || 0) + 1

          // Track monthly completions
          const monthName = monthNames[date.getMonth()]
          monthlyCompletions[monthName] = (monthlyCompletions[monthName] || 0) + 1
        }
      } catch (e) {
        console.error(`Error parsing date: ${dateStr}`, e)
      }
    }

    habitBreakdown[habit.name] = habitCompletions

    // Track longest streak in the year
    const yearStreak = calculateYearStreak(habit.completion_dates || [], year)
    if (yearStreak > longestStreak) {
      longestStreak = yearStreak
    }
  }

  // Find most consistent habit
  let mostConsistentHabit = 'None'
  let mostConsistentEmoji = '🌟'
  let maxCompletions = 0

  for (const [name, count] of Object.entries(habitBreakdown)) {
    if (count > maxCompletions) {
      maxCompletions = count
      mostConsistentHabit = name
      const habit = habits.find((h) => h.name === name)
      mostConsistentEmoji = habit?.emoji || '🌟'
    }
  }

  // Find best month
  let bestMonth = 'January'
  let maxMonthCompletions = 0
  for (const [month, count] of Object.entries(monthlyCompletions)) {
    if (count > maxMonthCompletions) {
      maxMonthCompletions = count
      bestMonth = month
    }
  }

  // Calculate perfect days
  let perfectDays = 0
  const totalHabitsPerDay = habits.length
  for (const count of Object.values(dailyCompletionCount)) {
    if (count >= totalHabitsPerDay) {
      perfectDays++
    }
  }

  // Calculate average completion rate
  const daysInYear = Math.ceil((yearEnd.getTime() - yearStart.getTime()) / (1000 * 60 * 60 * 24)) + 1
  const possibleCompletions = habits.length * daysInYear
  const avgCompletionRate = possibleCompletions > 0 ? totalCompletions / possibleCompletions : 0

  return {
    total_completions: totalCompletions,
    longest_streak: longestStreak,
    most_consistent_habit: mostConsistentHabit,
    most_consistent_emoji: mostConsistentEmoji,
    total_xp: totalXP,
    best_month: bestMonth,
    avg_completion_rate: avgCompletionRate,
    habit_breakdown: habitBreakdown,
    total_days_active: activeDays.size,
    perfect_days: perfectDays,
  }
}

/**
 * Calculate longest streak within a specific year
 */
function calculateYearStreak(completionDates: string[], year: number): number {
  const yearStart = new Date(year, 0, 1)
  const yearEnd = new Date(year, 11, 31)

  // Parse and filter dates for the year
  const dates = completionDates
    .map((dateStr) => {
      try {
        return new Date(dateStr)
      } catch {
        return null
      }
    })
    .filter((date) => date && date >= yearStart && date <= yearEnd)
    .sort((a, b) => a!.getTime() - b!.getTime()) as Date[]

  if (dates.length === 0) return 0

  let currentStreak = 1
  let maxStreak = 1

  for (let i = 1; i < dates.length; i++) {
    const daysDiff = Math.floor(
      (dates[i].getTime() - dates[i - 1].getTime()) / (1000 * 60 * 60 * 24)
    )

    if (daysDiff === 1) {
      currentStreak++
      if (currentStreak > maxStreak) {
        maxStreak = currentStreak
      }
    } else {
      currentStreak = 1
    }
  }

  return maxStreak
}
