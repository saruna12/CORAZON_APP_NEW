import 'dart:async';
import 'package:flutter/material.dart';
import 'soal_data.dart';
import 'hasil_test_page.dart';

class PreTestPage extends StatefulWidget {
  const PreTestPage({super.key});

  @override
  State<PreTestPage> createState() => _PreTestPageState();
}

class _PreTestPageState extends State<PreTestPage> {
  int _currentQuestionIndex = 0;
  final List<int> _userAnswersChoice = List.filled(daftarSoal.length, -1);
  final List<String> _userAnswersEsai = List.filled(daftarSoal.length, '');
  final TextEditingController _esaiController = TextEditingController();
  
  late Timer _timer;
  int _remainingSeconds = 300; // 5 Menit

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer.cancel();
        _navigateToHasil();
      }
    });
  }

  String _getFormattedTime() {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _navigateToHasil() {
    _timer.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HasilTestPage(
          userAnswersChoice: _userAnswersChoice,
          userAnswersEsai: _userAnswersEsai,
        ),
      ),
    );
  }

  bool _isJawabanTerisi(Soal soal) {
    if (soal.isEsai) {
      return _userAnswersEsai[_currentQuestionIndex].trim().isNotEmpty;
    } else {
      return _userAnswersChoice[_currentQuestionIndex] != -1;
    }
  }

  void _pindahSoalBerikutnya() {
    if (_currentQuestionIndex < daftarSoal.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _esaiController.text = _userAnswersEsai[_currentQuestionIndex];
      });
    } else {
      _navigateToHasil();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _esaiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const maroonColor = Color(0xFF801A24);
    const navyColor = Color(0xFF1B2A52);
    final currentSoal = daftarSoal[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / daftarSoal.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: maroonColor,
        elevation: 0,
        title: const Text('PRE TEST', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pertanyaan ${_currentQuestionIndex + 1} dari ${daftarSoal.length}', 
                    style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: maroonColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(_getFormattedTime(), style: const TextStyle(color: maroonColor, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE0E0E0),
                  valueColor: const AlwaysStoppedAnimation<Color>(maroonColor),
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Text(currentSoal.pertanyaan, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: navyColor, height: 1.5)),
              ),
              const SizedBox(height: 24),
              
              if (!currentSoal.isEsai && currentSoal.pilihan != null) ...[
                ...List.generate(currentSoal.pilihan!.length, (index) {
                  return _buildAnswerOption(index, currentSoal.pilihan![index]);
                }),
              ] else ...[
                const Text('Jawaban Esai Anda:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 8),
                TextField(
                  controller: _esaiController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Ketik jawaban analisis Anda di sini...',
                    filled: true,
                    fillColor: const Color(0xFFF8F9FA),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: maroonColor, width: 1.5)),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _userAnswersEsai[_currentQuestionIndex] = value;
                    });
                  },
                ),
              ],
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: maroonColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  onPressed: _isJawabanTerisi(currentSoal) ? _pindahSoalBerikutnya : null,
                  child: Text(
                    _currentQuestionIndex == daftarSoal.length - 1 ? 'SELESAI' : 'PERTANYAAN BERIKUTNYA',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerOption(int index, String text) {
    const maroonColor = Color(0xFF801A24);
    bool isSelected = _userAnswersChoice[_currentQuestionIndex] == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _userAnswersChoice[_currentQuestionIndex] = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? maroonColor.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? maroonColor : const Color(0xFFE0E0E0), width: isSelected ? 2 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(text, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? maroonColor : Colors.black87))),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? maroonColor : Colors.grey, width: 2), color: isSelected ? maroonColor : Colors.transparent),
              child: isSelected ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
            ),
          ],
        ),
      ),
    );
  }
}