-- ============================================
-- Year in Review Table Schema
-- ============================================
-- This table stores pre-calculated Year in Review statistics
-- for each user. Data is generated server-side via Edge Functions.

create table if not exists year_in_review (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users not null,
  year integer not null,
  
  -- Core Statistics
  total_completions integer not null,
  longest_streak integer not null,
  most_consistent_habit text not null,
  most_consistent_emoji text not null,
  total_xp integer not null,
  best_month text not null,
  avg_completion_rate real not null,
  habit_breakdown jsonb not null,
  total_days_active integer not null,
  perfect_days integer not null,
  
  -- Metadata
  generated_at timestamp with time zone default now(),
  expires_at timestamp with time zone, -- Optional: auto-delete after date
  
  -- Constraints
  unique(user_id, year),
  
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- ============================================
-- Row Level Security Policies
-- ============================================
alter table year_in_review enable row level security;

-- Users can only view their own year in review data
create policy "Users can view own year in review"
  on year_in_review for select
  using (auth.uid() = user_id);

-- Service role can insert (for Edge Functions)
create policy "Service role can insert year in review"
  on year_in_review for insert
  with check (true);

-- Service role can update
create policy "Service role can update year in review"
  on year_in_review for update
  using (true);

-- Users can delete their own data
create policy "Users can delete own year in review"
  on year_in_review for delete
  using (auth.uid() = user_id);

-- ============================================
-- Indexes for Performance
-- ============================================
create index if not exists year_in_review_user_year_idx 
  on year_in_review(user_id, year);

create index if not exists year_in_review_year_idx 
  on year_in_review(year);

create index if not exists year_in_review_generated_at_idx 
  on year_in_review(generated_at);

-- ============================================
-- Trigger for updated_at
-- ============================================
create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger update_year_in_review_updated_at
  before update on year_in_review
  for each row
  execute function update_updated_at_column();

-- ============================================
-- Comments
-- ============================================
comment on table year_in_review is 'Stores pre-calculated Year in Review statistics for users';
comment on column year_in_review.user_id is 'Reference to the user who owns this review';
comment on column year_in_review.year is 'The year this review is for (e.g., 2025)';
comment on column year_in_review.habit_breakdown is 'JSONB map of habit names to completion counts';
comment on column year_in_review.expires_at is 'Optional expiration date for automatic cleanup';
