// Replace the _fetchStats method:
Future<void> _fetchStats() async {
  setState(() => _isLoading = true);
  try {
    final response = await ApiClient.dio.get('/api/stats/coordinator');
    setState(() {
      _stats = response.data['stats'];
      _isLoading = false;
    });
  } catch (e) {
    setState(() => _isLoading = false);
    // Show error dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to load stats: ${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}