import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://ybuyeedkkwfysywxrphh.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlidXllZWRra3dmeXN5d3hycGhoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEyMDczOTAsImV4cCI6MjA4Njc4MzM5MH0.GdwkAsXGllI_47O87xMYSa8eM7Y_6Y0dBHLkjD889MA',
  );

  print('Fetching FinanzasPersonal...');
  final res = await supabase.from('FinanzasPersonal').select().limit(5);
  for (var row in res) {
    print('FinanzasPersonal: ID=${row['id']} personalID=${row['personalID']} fecha=${row['fecha']} QuienRegistro=${row['QuienRegistro']}');
  }

  print('\nFetching Personal...');
  final res2 = await supabase.from('Personal').select('userID, nombre').limit(5);
  for (var row in res2) {
    print('Personal: userID=${row['userID']} nombre=${row['nombre']}');
  }
}
