import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';
import 'package:nofacezone/src/Providers/AppProvider.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int userPoints = 350; // Puntos del usuario

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recompensas'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.textLight,
          unselectedLabelColor: AppColors.textLight.withValues(alpha: 0.6),
          indicatorColor: AppColors.accentBlue,
          indicatorWeight: 3,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Temas'),
            Tab(text: 'Fuentes'),
            Tab(text: 'Mensajes'),
            Tab(text: 'Badges'),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Barra de puntos
              _buildPointsBar(),
              // Contenido de las pestañas
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildThemesTab(),
                    _buildFontsTab(),
                    _buildMessagesTab(),
                    _buildBadgesTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointsBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.stars, color: Colors.amber, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tus puntos',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textLight,
                  ),
                ),
                Text(
                  '$userPoints puntos',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemesTab() {
    // Obtener el tema actual para mostrar los colores correctos
    final currentColorTheme = AppColors.getTheme(Provider.of<AppProvider>(context, listen: false).colorTheme) ?? AppColors.currentTheme;
    
    final themes = [
      _RewardTheme(
        id: 'ocean',
        name: 'Océano Azul',
        description: 'Un tema relajante inspirado en el mar',
        colors: const [
          Color(0xFF7F53AC), // primaryPurple
          Color(0xFF647DEE), // primaryBlue
          Color(0xFFB8C1FF), // lightLavender
        ],
        price: 0,
        unlocked: true,
        icon: Icons.water_drop,
      ),
      _RewardTheme(
        id: 'sunset',
        name: 'Atardecer',
        description: 'Colores cálidos del atardecer',
        colors: [Colors.orange[800]!, Colors.pink[400]!, Colors.purple[300]!],
        price: 100,
        unlocked: userPoints >= 100,
        icon: Icons.wb_twilight,
      ),
      _RewardTheme(
        id: 'forest',
        name: 'Bosque Verde',
        description: 'Tema natural y relajante',
        colors: [Colors.green[800]!, Colors.lightGreen[400]!, Colors.lime[300]!],
        price: 150,
        unlocked: userPoints >= 150,
        icon: Icons.park,
      ),
      _RewardTheme(
        id: 'lavender',
        name: 'Lavanda',
        description: 'Suave y relajante',
        colors: [Colors.purple[800]!, Colors.deepPurple[400]!, Colors.indigo[300]!],
        price: 200,
        unlocked: userPoints >= 200,
        icon: Icons.local_florist,
      ),
      _RewardTheme(
        id: 'coral',
        name: 'Coral',
        description: 'Vibrante y energético',
        colors: [Colors.red[700]!, Colors.orange[400]!, Colors.yellow[300]!],
        price: 250,
        unlocked: userPoints >= 250,
        icon: Icons.whatshot,
      ),
      _RewardTheme(
        id: 'midnight',
        name: 'Medianoche',
        description: 'Elegante y sofisticado',
        colors: [Colors.grey[900]!, Colors.blueGrey[800]!, Colors.grey[700]!],
        price: 300,
        unlocked: userPoints >= 300,
        icon: Icons.nights_stay,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎨 Temas de colores',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Desbloquea nuevos temas personalizando tu experiencia',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textLight.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: themes.length,
            itemBuilder: (context, index) {
              return _buildThemeCard(themes[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(_RewardTheme theme) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final currentTheme = Provider.of<AppProvider>(context).colorTheme;
    final isSelected = currentTheme == theme.id;

    return GestureDetector(
      onTap: theme.unlocked
          ? () async {
              await appProvider.setColorTheme(theme.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tema "${theme.name}" aplicado ✨'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          : null,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: theme.colors,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.textLight
                  : theme.unlocked
                      ? AppColors.textLight.withValues(alpha: 0.3)
                      : AppColors.textLight.withValues(alpha: 0.1),
              width: isSelected ? 3 : 2,
            ),
          boxShadow: [
            BoxShadow(
              color: theme.colors[0].withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(theme.icon, color: Colors.white, size: 28),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.check_circle, color: Colors.white, size: 20),
                        )
                      else if (!theme.unlocked)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.lock, color: Colors.white, size: 16),
                        ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        theme.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        theme.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  if (!theme.unlocked)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${theme.price}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                    else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? Icons.star : Icons.check_circle,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isSelected ? 'Activo' : 'Disponible',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontsTab() {
    final fonts = [
      _RewardFont(
        id: 'default',
        name: 'Roboto',
        description: 'Fuente estándar y legible',
        unlocked: true,
        price: 0,
      ),
      _RewardFont(
        id: 'elegant',
        name: 'Playfair Display',
        description: 'Elegante y sofisticada',
        unlocked: userPoints >= 100,
        price: 100,
      ),
      _RewardFont(
        id: 'modern',
        name: 'Poppins',
        description: 'Moderna y minimalista',
        unlocked: userPoints >= 150,
        price: 150,
      ),
      _RewardFont(
        id: 'friendly',
        name: 'Comfortaa',
        description: 'Amigable y redondeada',
        unlocked: userPoints >= 200,
        price: 200,
      ),
      _RewardFont(
        id: 'bold',
        name: 'Montserrat',
        description: 'Audaz y llamativa',
        unlocked: userPoints >= 250,
        price: 250,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '✍️ Tipos de letra',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Personaliza la tipografía de la aplicación',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textLight.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),
          ...fonts.map((font) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildFontCard(font),
              )),
        ],
      ),
    );
  }

  Widget _buildFontCard(_RewardFont font) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final currentFont = Provider.of<AppProvider>(context).fontFamily;
    final isSelected = currentFont == font.id;

    return GestureDetector(
      onTap: font.unlocked
          ? () async {
              await appProvider.setFontFamily(font.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Fuente "${font.name}" aplicada ✨'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.textLight.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.textLight
                : font.unlocked
                    ? AppColors.accentBlue.withValues(alpha: 0.5)
                    : AppColors.textLight.withValues(alpha: 0.2),
            width: isSelected ? 2.5 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: font.unlocked
                    ? LinearGradient(colors: AppColors.accentGradient)
                    : null,
                color: font.unlocked ? null : AppColors.textLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                font.unlocked ? Icons.text_fields : Icons.lock,
                color: AppColors.textLight,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    font.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    font.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight.withValues(alpha: 0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!font.unlocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${font.price}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? Icons.star : Icons.check_circle,
                      color: isSelected ? Colors.white : Colors.green,
                      size: 18,
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 4),
                      const Text(
                        'Activa',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesTab() {
    final messages = [
      _MotivationalMessage(
        id: 'daily',
        title: 'Mensajes diarios',
        description: 'Mensajes motivacionales cada día',
        unlocked: true,
        price: 0,
        examples: [
          '✨ Cada día es una nueva oportunidad',
          '💪 Eres más fuerte de lo que crees',
          '🌟 Tus pequeños pasos llevan a grandes cambios',
        ],
      ),
      _MotivationalMessage(
        id: 'achievements',
        title: 'Mensajes de logros',
        description: 'Celebra tus éxitos',
        unlocked: userPoints >= 100,
        price: 100,
        examples: [
          '🎉 ¡Increíble! Lograste tu meta',
          '🏆 Has superado tus expectativas',
          '⭐ Eres un ejemplo de perseverancia',
        ],
      ),
      _MotivationalMessage(
        id: 'encouragement',
        title: 'Mensajes de aliento',
        description: 'Motivación en momentos difíciles',
        unlocked: userPoints >= 150,
        price: 150,
        examples: [
          '🌱 Todo crecimiento requiere tiempo',
          '💫 Tus esfuerzos no pasan desapercibidos',
          '🌺 Eres capaz de superar cualquier obstáculo',
        ],
      ),
      _MotivationalMessage(
        id: 'wisdom',
        title: 'Sabiduría diaria',
        description: 'Frases inspiradoras de grandes pensadores',
        unlocked: userPoints >= 200,
        price: 200,
        examples: [
          '🧘 La paz viene de dentro',
          '🎯 El éxito es la suma de pequeños esfuerzos',
          '🌈 La persistencia supera la resistencia',
        ],
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💬 Mensajes motivacionales',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
              Text(
            'Desbloquea colecciones de mensajes inspiradores',
                style: TextStyle(
              fontSize: 14,
              color: AppColors.textLight.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),
          ...messages.map((message) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildMessageCard(message),
              )),
        ],
      ),
    );
  }

  Widget _buildMessageCard(_MotivationalMessage message) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final activeCollections = Provider.of<AppProvider>(context).activeMessageCollections;
    final isActive = activeCollections.contains(message.id);

    return GestureDetector(
      onTap: message.unlocked
          ? () async {
              await appProvider.toggleMessageCollection(message.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isActive
                          ? 'Colección "${message.title}" desactivada'
                          : 'Colección "${message.title}" activada ✨',
                    ),
                    backgroundColor: isActive ? Colors.orange : Colors.green,
                  ),
                );
              }
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.textLight.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppColors.textLight
                : message.unlocked
                    ? AppColors.accentPurple.withValues(alpha: 0.5)
                    : AppColors.textLight.withValues(alpha: 0.2),
            width: isActive ? 2.5 : 1.5,
          ),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: message.unlocked
                      ? LinearGradient(colors: AppColors.accentGradient)
                      : null,
                  color: message.unlocked ? null : AppColors.textLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  message.unlocked ? Icons.message : Icons.lock,
                  color: AppColors.textLight,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                    ),
                    Text(
                      message.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textLight.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (!message.unlocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${message.price}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? Icons.star : Icons.check_circle,
                        color: isActive ? Colors.white : Colors.green,
                        size: 18,
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 4),
                        const Text(
                          'Activa',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
          if (message.unlocked) ...[
            const SizedBox(height: 16),
            ...message.examples.map((example) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.textLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      example,
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textLight.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                )),
          ],
        ],
      ),
      ),
    );
  }

  Widget _buildBadgesTab() {
    final badges = [
      _RewardBadge(
        id: 'first_steps',
        name: 'Primeros Pasos',
        description: 'Completa 3 días consecutivos',
        icon: Icons.directions_walk,
        color: Colors.blue,
        unlocked: true,
        progress: 1.0,
      ),
      _RewardBadge(
        id: 'week_warrior',
        name: 'Guerrero Semanal',
        description: 'Completa 7 días consecutivos',
        icon: Icons.calendar_today,
        color: Colors.purple,
        unlocked: userPoints >= 100,
        progress: 0.6,
      ),
      _RewardBadge(
        id: 'month_master',
        name: 'Maestro Mensual',
        description: 'Completa 30 días consecutivos',
        icon: Icons.star,
        color: Colors.amber,
        unlocked: userPoints >= 200,
        progress: 0.3,
      ),
      _RewardBadge(
        id: 'time_saver',
        name: 'Ahorrador de Tiempo',
        description: 'Ahorra 50 horas libres',
        icon: Icons.access_time,
        color: Colors.green,
        unlocked: userPoints >= 150,
        progress: 0.7,
      ),
      _RewardBadge(
        id: 'early_bird',
        name: 'Madrugador',
        description: 'Completa 5 días antes del mediodía',
        icon: Icons.wb_sunny,
        color: Colors.yellow,
        unlocked: userPoints >= 180,
        progress: 0.4,
      ),
      _RewardBadge(
        id: 'streak_master',
        name: 'Maestro de Racha',
        description: 'Mantén 10 días consecutivos',
        icon: Icons.local_fire_department,
        color: Colors.red,
        unlocked: userPoints >= 250,
        progress: 0.5,
      ),
      _RewardBadge(
        id: 'goal_crusher',
        name: 'Destructor de Metas',
        description: 'Cumple todas las metas semanales',
        icon: Icons.flag,
        color: Colors.indigo,
        unlocked: userPoints >= 300,
        progress: 0.6,
      ),
      _RewardBadge(
        id: 'zen_master',
        name: 'Maestro Zen',
        description: '10 horas libres en un día',
        icon: Icons.spa,
        color: Colors.teal,
        unlocked: userPoints >= 200,
        progress: 0.3,
      ),
      _RewardBadge(
        id: 'night_owl',
        name: 'Búho Nocturno',
        description: 'Completa 5 días después de medianoche',
        icon: Icons.nights_stay,
        color: Colors.deepPurple,
        unlocked: userPoints >= 220,
        progress: 0.2,
      ),
      _RewardBadge(
        id: 'unstoppable',
        name: 'Imparable',
        description: '15 días consecutivos sin faltar',
        icon: Icons.speed,
        color: Colors.pink,
        unlocked: userPoints >= 280,
        progress: 0.8,
      ),
      _RewardBadge(
        id: 'legend',
        name: 'Leyenda',
        description: 'Completa 100 días consecutivos',
        icon: Icons.emoji_events,
        color: Colors.orange,
        unlocked: userPoints >= 400,
        progress: 0.1,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏆 Badges y Logros',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Desbloquea badges especiales por tus logros',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textLight.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),
          ...badges.map((badge) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildBadgeCard(badge),
              )),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(_RewardBadge badge) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badge.unlocked
              ? badge.color.withValues(alpha: 0.5)
              : AppColors.textLight.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: badge.unlocked
                  ? badge.color.withValues(alpha: 0.2)
                  : AppColors.textLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: badge.unlocked ? badge.color : AppColors.textLight.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Icon(
              badge.unlocked ? badge.icon : Icons.lock,
              color: badge.unlocked ? badge.color : AppColors.textLight.withValues(alpha: 0.5),
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  badge.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textLight.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                if (!badge.unlocked)
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.textLight.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: badge.progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: badge.color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (badge.unlocked)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 28),
            )
          else
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.textLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(badge.progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight.withValues(alpha: 0.7),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Modelos de datos
class _RewardTheme {
  final String id;
  final String name;
  final String description;
  final List<Color> colors;
  final int price;
  final bool unlocked;
  final IconData icon;

  _RewardTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.colors,
    required this.price,
    required this.unlocked,
    required this.icon,
  });
}

class _RewardFont {
  final String id;
  final String name;
  final String description;
  final int price;
  final bool unlocked;

  _RewardFont({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.unlocked,
  });
}

class _MotivationalMessage {
  final String id;
  final String title;
  final String description;
  final List<String> examples;
  final int price;
  final bool unlocked;

  _MotivationalMessage({
    required this.id,
    required this.title,
    required this.description,
    required this.examples,
    required this.price,
    required this.unlocked,
  });
}

class _RewardBadge {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool unlocked;
  final double progress;

  _RewardBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.unlocked,
    required this.progress,
  });
}
