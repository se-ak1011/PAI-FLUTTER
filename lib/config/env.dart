class Env {
  static const String supabaseUrl = 'https://ehektgshhvtbijotqaos.supabase.co/';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVoZWt0Z3NoaHZ0Ymlqb3RxYW9zIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEyODA4ODksImV4cCI6MjA5Njg1Njg4OX0.os4eQPVkDcwu2naDnLkGz6cTS68Jvn2I8zYoagwt8tY';
  static const String openAIApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );
}
