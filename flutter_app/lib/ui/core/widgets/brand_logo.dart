import 'package:flutter/material.dart';

/// Reusable widget that renders authentic logos for smartphone & electronics brands.
class BrandLogo extends StatelessWidget {
  final String brand;
  final double size;

  const BrandLogo({
    super.key,
    required this.brand,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    switch (brand.toLowerCase().trim()) {
      case 'apple':
        return Icon(
          Icons.apple,
          size: size,
          color: const Color(0xFF111827),
        );

      case 'samsung':
        return const Text(
          'SAMSUNG',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0C4DA2),
            letterSpacing: 0.3,
          ),
        );

      case 'google':
        return ShaderMask(
          shaderCallback: (bounds) => const SweepGradient(
            colors: [
              Color(0xFF4285F4), // Blue
              Color(0xFFEA4335), // Red
              Color(0xFFFBBC05), // Yellow
              Color(0xFF34A853), // Green
              Color(0xFF4285F4), // Blue
            ],
          ).createShader(bounds),
          child: const Text(
            'G',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        );

      case 'oneplus':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFEB0028), width: 1.8),
            borderRadius: BorderRadius.circular(3),
          ),
          child: const Text(
            '1+',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFFEB0028),
              letterSpacing: -0.5,
            ),
          ),
        );

      case 'xiaomi':
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFFFF6900),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: const Text(
            'mi',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        );

      case 'honor':
        return const Text(
          'HONOR',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            color: Color(0xFF007DFE),
            letterSpacing: 0.5,
          ),
        );

      case 'hp':
        return Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF0096D6),
          ),
          alignment: Alignment.center,
          child: const Text(
            'hp',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontStyle: FontStyle.italic,
            ),
          ),
        );

      case 'dell':
        return const Text(
          'DELL',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Color(0xFF007DB8),
            letterSpacing: 0.5,
          ),
        );

      case 'lenovo':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          decoration: BoxDecoration(
            color: const Color(0xFFE2231A),
            borderRadius: BorderRadius.circular(2),
          ),
          child: const Text(
            'Lenovo',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        );

      case 'asus':
        return const Text(
          'ASUS',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
            color: Color(0xFF00539B),
            letterSpacing: 0.5,
          ),
        );

      case 'sony':
        return const Text(
          'SONY',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
            color: Color(0xFF111827),
            letterSpacing: 1.0,
          ),
        );

      case 'huawei':
        return const Text(
          'HUAWEI',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            color: Color(0xFFCF0A2C),
            letterSpacing: 0.5,
          ),
        );

      case 'oppo':
        return const Text(
          'oppo',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Color(0xFF048753),
          ),
        );

      case 'vivo':
        return const Text(
          'vivo',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Color(0xFF415FFF),
          ),
        );

      case 'realme':
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFFFFC915),
            borderRadius: BorderRadius.circular(5),
          ),
          alignment: Alignment.center,
          child: const Text(
            'R',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        );

      case 'motorola':
        return Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF001438),
          ),
          alignment: Alignment.center,
          child: const Text(
            'M',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontStyle: FontStyle.italic,
            ),
          ),
        );

      case 'nothing':
        return const Text(
          '( )',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Color(0xFF111827),
            letterSpacing: 1.0,
          ),
        );

      case 'microsoft':
        return SizedBox(
          width: 18,
          height: 18,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 8, height: 8, color: const Color(0xFFF25022)),
                  const SizedBox(width: 2),
                  Container(width: 8, height: 8, color: const Color(0xFF7FBA00)),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 8, height: 8, color: const Color(0xFF00A4EF)),
                  const SizedBox(width: 2),
                  Container(width: 8, height: 8, color: const Color(0xFFFFB900)),
                ],
              ),
            ],
          ),
        );

      case 'nokia':
        return const Text(
          'NOKIA',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Color(0xFF124191),
            letterSpacing: 0.5,
          ),
        );

      case 'razer':
        return const Icon(
          Icons.sports_esports_outlined,
          size: 22,
          color: Color(0xFF00FF00),
        );

      case 'lg':
        return Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFA50034),
          ),
          alignment: Alignment.center,
          child: const Text(
            'LG',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        );

      case 'poco':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(3),
          ),
          child: const Text(
            'POCO',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFFDD00),
            ),
          ),
        );

      case 'tecno':
        return const Text(
          'TECNO',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0056B3),
            letterSpacing: 0.5,
          ),
        );

      case 'infinix':
        return const Text(
          'Infinix',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Color(0xFF00A859),
          ),
        );

      case 'tcl':
        return const Text(
          'TCL',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Color(0xFFE60012),
            letterSpacing: 0.5,
          ),
        );

      case 'zte':
        return const Text(
          'ZTE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0078D7),
            letterSpacing: 0.5,
          ),
        );

      case 'acer':
        return const Text(
          'acer',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Color(0xFF83B81A),
          ),
        );

      case 'htc':
        return const Text(
          'htc',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Color(0xFF85A82B),
          ),
        );

      case 'blackberry':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(3),
          ),
          child: const Text(
            'BB',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        );

      case 'alienware':
        return const Icon(
          Icons.smart_toy_outlined,
          size: 22,
          color: Color(0xFF00D2FF),
        );

      default:
        return Text(
          brand.isNotEmpty ? brand[0].toUpperCase() : '',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        );
    }
  }
}
