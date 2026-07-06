import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/location/location_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/diagnosis_scale_bar.dart';
import '../../../shared/widgets/diagnosis_visuals.dart';
import '../../project/application/project_providers.dart';
import '../application/measurement_providers.dart';
import '../domain/calculators/impact_penetrometer_calculator.dart';
import '../domain/calculators/pressure_penetrometer_calculator.dart';
import '../domain/entities/measurement.dart';
import '../domain/entities/penetrometer_type.dart';
import '../domain/services/soil_diagnosis_service.dart';

/// Cadastro de medição (impacto ou pressão) com cálculo e diagnóstico ao vivo,
/// equivalente ao `save()` dos controllers JavaFX.
class NewMeasurementPage extends ConsumerStatefulWidget {
  const NewMeasurementPage({super.key, this.projectId});

  /// Se informado, a medição já nasce vinculada a este projeto.
  final int? projectId;

  @override
  ConsumerState<NewMeasurementPage> createState() => _NewMeasurementPageState();
}

class _NewMeasurementPageState extends ConsumerState<NewMeasurementPage> {
  PenetrometerType _type = PenetrometerType.impact;

  final _collector = TextEditingController();
  final _place = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final _impacts = TextEditingController();
  final _deep = TextEditingController();
  final _pressure = TextEditingController();
  final _customDepth = TextEditingController();

  int? _standardDepth;
  DateTime _date = DateTime.now();
  bool _saving = false;
  bool _gettingLocation = false;
  int? _projectId;

  @override
  void initState() {
    super.initState();
    _projectId = widget.projectId;
  }

  @override
  void dispose() {
    for (final c in [
      _collector,
      _place,
      _lat,
      _lng,
      _impacts,
      _deep,
      _pressure,
      _customDepth,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isImpact => _type == PenetrometerType.impact;

  double get _liveCoefficient {
    if (_isImpact) {
      final n = int.tryParse(_impacts.text.trim()) ?? 0;
      return ImpactPenetrometerCalculator.calculateCoefficient(n);
    } else {
      final mpa = double.tryParse(_pressure.text.trim()) ?? 0;
      return PressurePenetrometerCalculator.calculateCoefficient(mpa);
    }
  }

  double get _selectedDepth {
    final custom = double.tryParse(_customDepth.text.trim());
    if (custom != null && custom > 0) return custom;
    return (_standardDepth ?? 0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final coefficient = _liveCoefficient;
    final hasValue = coefficient > 0;
    final projects = ref.watch(projectsProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Nova Medição')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          SegmentedButton<PenetrometerType>(
            segments: const [
              ButtonSegment(
                value: PenetrometerType.impact,
                label: Text('Impacto'),
                icon: Icon(Icons.hardware),
              ),
              ButtonSegment(
                value: PenetrometerType.pressure,
                label: Text('Pressão'),
                icon: Icon(Icons.compress),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: AppSpacing.lg),
          _section('Identificação'),
          TextField(
            controller: _collector,
            decoration: const InputDecoration(
              labelText: 'Nome do coletor',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (projects.isNotEmpty) ...[
            _section('Projeto'),
            DropdownButtonFormField<int?>(
              initialValue: _projectId,
              decoration: const InputDecoration(
                labelText: 'Projeto (opcional)',
                prefixIcon: Icon(Icons.folder_outlined),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Nenhum'),
                ),
                ...projects.map(
                  (p) => DropdownMenuItem<int?>(
                    value: p.id,
                    child: Text(p.name),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _projectId = v),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          _section('Localização'),
          TextField(
            controller: _place,
            decoration: const InputDecoration(
              labelText: 'Local da medição',
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _coordField(_lat, 'Latitude')),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _coordField(_lng, 'Longitude')),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _gettingLocation ? null : _useGps,
              icon: _gettingLocation
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: const Text('Usar GPS'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _section('Medição'),
          if (_isImpact) ..._impactFields() else ..._pressureFields(),
          const SizedBox(height: AppSpacing.md),
          _dateField(),
          const SizedBox(height: AppSpacing.lg),
          _ResultCard(
            coefficient: coefficient,
            diagnosis:
                hasValue ? SoilDiagnosisService.diagnose(coefficient) : '—',
            hasValue: hasValue,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Salvar medição'),
          ),
        ],
      ),
    );
  }

  List<Widget> _impactFields() => [
        TextField(
          controller: _impacts,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Número de impactos (N)',
            prefixIcon: Icon(Icons.numbers),
            helperText: 'Equação de Stolf: R = 5.6 + 6.89 × N',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _deep,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Profundidade (cm)',
            prefixIcon: Icon(Icons.straighten),
          ),
        ),
      ];

  List<Widget> _pressureFields() => [
        Wrap(
          spacing: AppSpacing.sm,
          children: PressurePenetrometerCalculator.standardDepths.map((d) {
            return ChoiceChip(
              label: Text('$d cm'),
              selected: _standardDepth == d && _customDepth.text.isEmpty,
              onSelected: (_) => setState(() {
                _standardDepth = d;
                _customDepth.clear();
              }),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _customDepth,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) => setState(() {
            if (v.isNotEmpty) _standardDepth = null;
          }),
          decoration: const InputDecoration(
            labelText: 'Profundidade personalizada (cm)',
            prefixIcon: Icon(Icons.straighten),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _pressure,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Leitura do manômetro (MPa)',
            prefixIcon: Icon(Icons.speed),
            helperText: 'Conversão: 1 MPa = 10.1972 kgf/cm²',
          ),
        ),
      ];

  Widget _coordField(TextEditingController c, String label) {
    return TextField(
      controller: c,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true, signed: true),
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _dateField() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _date,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) setState(() => _date = picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Data da medição',
          prefixIcon: Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          '${_date.day.toString().padLeft(2, '0')}/'
          '${_date.month.toString().padLeft(2, '0')}/${_date.year}',
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      );

  Future<void> _useGps() async {
    setState(() => _gettingLocation = true);
    try {
      final point =
          await ref.read(locationServiceProvider).getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _lat.text = point.latitude.toStringAsFixed(6);
        _lng.text = point.longitude.toStringAsFixed(6);
      });
    } on LocationFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível obter a localização.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  String? _validate() {
    if (_collector.text.trim().isEmpty) return 'Informe o nome do coletor.';
    if (_place.text.trim().isEmpty) return 'Informe o local da medição.';
    final lat = double.tryParse(_lat.text.trim());
    final lng = double.tryParse(_lng.text.trim());
    if (lat == null) return 'Latitude inválida.';
    if (lng == null) return 'Longitude inválida.';
    if (_isImpact) {
      final n = int.tryParse(_impacts.text.trim()) ?? 0;
      if (n <= 0) return 'Número de impactos deve ser maior que zero.';
      if ((double.tryParse(_deep.text.trim()) ?? 0) <= 0) {
        return 'Informe a profundidade.';
      }
    } else {
      if ((double.tryParse(_pressure.text.trim()) ?? 0) <= 0) {
        return 'Informe a leitura do manômetro.';
      }
      if (_selectedDepth <= 0) return 'Selecione ou informe a profundidade.';
    }
    return null;
  }

  Future<void> _save() async {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() => _saving = true);

    final lat = double.parse(_lat.text.trim());
    final lng = double.parse(_lng.text.trim());

    final Measurement measurement = _isImpact
        ? Measurement.impact(
            impacts: int.parse(_impacts.text.trim()),
            deep: double.parse(_deep.text.trim()),
            latitude: lat,
            longitude: lng,
            place: _place.text.trim(),
            nameCollector: _collector.text.trim(),
            meteringDate: _date,
            projectId: _projectId,
          )
        : Measurement.pressure(
            pressureMpa: double.parse(_pressure.text.trim()),
            deep: _selectedDepth,
            latitude: lat,
            longitude: lng,
            place: _place.text.trim(),
            nameCollector: _collector.text.trim(),
            meteringDate: _date,
            projectId: _projectId,
          );

    final saved =
        await ref.read(measurementsProvider.notifier).add(measurement);

    if (!mounted) return;
    setState(() => _saving = false);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Medição #${saved.id} salva.')),
    );
    context.pop();
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.coefficient,
    required this.diagnosis,
    required this.hasValue,
  });

  final double coefficient;
  final String diagnosis;
  final bool hasValue;

  @override
  Widget build(BuildContext context) {
    final color = hasValue ? diagnosisColor(coefficient) : Colors.grey;
    return Card(
      color: color.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        side: BorderSide(color: color, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: color, size: 36),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, animation) =>
                            FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: animation,
                            child: child,
                          ),
                        ),
                        child: Text(
                          hasValue
                              ? '${coefficient.toStringAsFixed(2)} kgf/cm²'
                              : '— kgf/cm²',
                          key: ValueKey(coefficient.toStringAsFixed(2)),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      Text(diagnosis,
                          style: Theme.of(context).textTheme.bodyMedium,),
                    ],
                  ),
                ),
              ],
            ),
            _ResultBody(coefficient: coefficient, hasValue: hasValue),
          ],
        ),
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.coefficient, required this.hasValue});

  final double coefficient;
  final bool hasValue;

  @override
  Widget build(BuildContext context) {
    if (!hasValue) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: DiagnosisScaleBar(coefficient: coefficient),
    );
  }
}
