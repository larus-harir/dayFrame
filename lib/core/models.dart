import 'format.dart';

String generateId() => DateTime.now().microsecondsSinceEpoch.toString();

class TaskItem {
  TaskItem({required this.id, required this.title, this.days = const [1,2,3,4,5,6,7], List<String>? completedDates}) : completedDates = List.of(completedDates ?? const []);
  final String id;
  String title;
  List<int> days;
  List<String> completedDates;
  bool isScheduled(DateTime date) => days.contains(date.weekday);
  bool isDone(DateTime date) => completedDates.contains(dayKey(date));
  Map<String,dynamic> toJson() => {'id':id,'title':title,'days':days,'completedDates':completedDates};
  factory TaskItem.fromJson(Map<String,dynamic> json) => TaskItem(
    id: json['id']?.toString() ?? generateId(),
    title: json['title']?.toString() ?? '',
    days: (json['days'] as List? ?? [1,2,3,4,5,6,7]).map((v) => (v as num).toInt()).toList(),
    completedDates: (json['completedDates'] as List? ?? []).map((v) => v.toString()).toList(),
  );
}

class PlannerEvent {
  PlannerEvent({required this.id,required this.title,required this.date,required this.hour,required this.minute,this.memo='',this.pinned=true});
  final String id;
  String title;
  String date;
  int hour;
  int minute;
  String memo;
  bool pinned;
  String get clock => formatTime(hour, minute);
  Map<String,dynamic> toJson() => {'id':id,'title':title,'date':date,'hour':hour,'minute':minute,'memo':memo,'pinned':pinned};
  factory PlannerEvent.fromJson(Map<String,dynamic> json) => PlannerEvent(
    id: json['id']?.toString() ?? generateId(),
    title: json['title']?.toString() ?? '',
    date: json['date']?.toString() ?? dayKey(DateTime.now()),
    hour: (json['hour'] as num?)?.toInt() ?? 9,
    minute: (json['minute'] as num?)?.toInt() ?? 0,
    memo: json['memo']?.toString() ?? '', pinned: json['pinned'] != false,
  );
}

class PlannerNote {
  PlannerNote({required this.id,required this.text,this.pinned=false,required this.createdAt});
  final String id;
  String text;
  bool pinned;
  String createdAt;
  Map<String,dynamic> toJson() => {'id':id,'text':text,'pinned':pinned,'createdAt':createdAt};
  factory PlannerNote.fromJson(Map<String,dynamic> json) => PlannerNote(
    id: json['id']?.toString() ?? generateId(), text: json['text']?.toString() ?? '',
    pinned: json['pinned'] == true, createdAt: json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
  );
}

class GoalItem {
  GoalItem({required this.id,required this.title,this.description='',this.deadline='',this.pinned=true,required this.steps,required this.finishedSteps});
  final String id;
  String title;
  String description;
  String deadline;
  bool pinned;
  List<String> steps;
  List<bool> finishedSteps;
  double get progress => steps.isEmpty ? 0 : finishedSteps.where((x) => x).length / steps.length;
  Map<String,dynamic> toJson() => {
    'id':id,'title':title,'description':description,'deadline':deadline,
    'pinned':pinned,'steps':steps,'finishedSteps':finishedSteps,
  };
  factory GoalItem.fromJson(Map<String,dynamic> json) {
    final steps = (json['steps'] as List? ?? []).map((v) => v.toString()).toList();
    final completed = (json['finishedSteps'] as List? ?? []).map((v) => v == true).toList();
    return GoalItem(
      id: json['id']?.toString() ?? generateId(), title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '', deadline: json['deadline']?.toString() ?? '',
      pinned: json['pinned'] != false, steps: steps,
      finishedSteps: List.generate(steps.length, (i) => i < completed.length && completed[i]),
    );
  }
}

class DisplayPreferences {
  DisplayPreferences();

  bool bible = true;
  bool tasks = true;
  bool goals = true;
  bool notes = true;
  bool events = true;
  bool hidePrivateDetails = true;
  bool darkMode = false;
  bool lockSurfaceEnabled = false;
  Map<String,dynamic> toJson() => {
    'bible':bible,'tasks':tasks,'goals':goals,'notes':notes,'events':events,
    'lockSurfaceEnabled':lockSurfaceEnabled, 'hidePrivateDetails':hidePrivateDetails,'darkMode':darkMode,
  };
  factory DisplayPreferences.fromJson(Map<String,dynamic> json) {
    final value = DisplayPreferences();
    value.bible = json['bible'] != false;
    value.tasks = json['tasks'] != false;
    value.goals = json['goals'] != false;
    value.notes = json['notes'] != false;
    value.events = json['events'] != false;
    value.hidePrivateDetails = json['hidePrivateDetails'] != false;
    value.lockSurfaceEnabled = json['lockSurfaceEnabled'] == true;
    value.darkMode = json['darkMode'] == true;
    return value;
  }
}
