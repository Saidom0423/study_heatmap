import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://vulfsfclfyzjbelnuhzt.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ1bGZzZmNsZnl6amJlbG51aHp0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE2Nzc1MTQsImV4cCI6MjA5NzI1MzUxNH0.CqIVXTsK9CDGkBtski3r-IOWQmCHASdN1l3XVjPonGE';
}

// Handy global getter used throughout the app
final supabase = Supabase.instance.client;