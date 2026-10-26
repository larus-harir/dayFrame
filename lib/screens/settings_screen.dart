import 'package:flutter/material.dart';
import '../core/store.dart';
import '../core/lock_surface.dart';
import '../widgets/common.dart';
import '../widgets/overlay_settings_card.dart';
import 'preview_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key,required this.store});
  final PlannerStore store;
  @override Widget build(BuildContext context){
    final pref=store.display;
    return ListView(padding:const EdgeInsets.fromLTRB(18,12,18,110),children:[
      Text('설정',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),
      const SizedBox(height:8),Text('내가 보고 싶은 영역을 선택하세요.',style:Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height:24),const SectionHeading('오늘 화면 / 프리뷰 표시 항목'),
      Panel(child:Column(children:[
        SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('오늘의 일정'),value:pref.events,onChanged:(v)=>store.updateDisplay((p)=>p.events=v)),
        SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('성경 일독'),value:pref.bible,onChanged:(v)=>store.updateDisplay((p)=>p.bible=v)),
        SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('데일리 체크리스트'),value:pref.tasks,onChanged:(v)=>store.updateDisplay((p)=>p.tasks=v)),
        SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('장기 플랜'),value:pref.goals,onChanged:(v)=>store.updateDisplay((p)=>p.goals=v)),
        SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('메모'),value:pref.notes,onChanged:(v)=>store.updateDisplay((p)=>p.notes=v)),
      ])),
      const SizedBox(height:22),const SectionHeading('모양과 개인정보'),
      Panel(child:Column(children:[
        SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('다크 모드'),value:pref.darkMode,onChanged:(v)=>store.updateDisplay((p)=>p.darkMode=v)),
        SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('프리뷰·잠금 요약에서 개인 내용 숨기기'),
          subtitle:const Text('잠금화면에 표시될 수 있는 개인 내용을 숨기는 설정입니다.'),
          value:pref.hidePrivateDetails,onChanged:(v)=>store.updateDisplay((p)=>p.hidePrivateDetails=v)),
      ])),
      const SizedBox(height:22),const OverlaySettingsCard(),
      const SizedBox(height:22),const SectionHeading('요약 프리뷰 (보조 기능)'),
      Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('현재는 잠금화면처럼 보이는 앱 내부 테스트 화면입니다. 휴대폰을 켤 때마다 자동 실행되지는 않습니다.'),
        const SizedBox(height:14),SizedBox(width:double.infinity,child:FilledButton.icon(
          onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>PreviewScreen(store:store))),
          icon:const Icon(Icons.phone_android),label:const Text('프리뷰 실행'))),
      ])),
      const SizedBox(height:22),const SectionHeading('수동 요약 타일 (읽기 전용)'),
      Panel(child:Column(children:[
        const Text('빠른 설정 편집에서 DAYFRAME 타일을 추가한 뒤 직접 눌러 여세요. 화면을 켤 때 자동으로 실행하지 않으며 휴대폰 잠금을 해제하지 않습니다. 갤럭시에서 잠금 중 타일 실행은 OS 정책에 따라 제한될 수 있습니다.'),
        SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('수동 요약 타일 사용'),
          value:pref.lockSurfaceEnabled,onChanged:!LockSurface.supported?null:(v)async{
            store.updateDisplay((p)=>p.lockSurfaceEnabled=v);
            try { await LockSurface.sync(store); } catch (_) { if(context.mounted)showMessage(context,'Android 연동을 확인해주세요.'); }
          }),
        FilledButton(onPressed:!LockSurface.supported || !pref.lockSurfaceEnabled?null:()async{
          try { await LockSurface.open(store); } catch (_) { if(context.mounted)showMessage(context,'네이티브 연동 또는 기기 지원을 확인해주세요.'); }
        },child:const Text('읽기 전용 요약 열기')),
      ])),
      const SizedBox(height:22),const SectionHeading('저장 방식'),
      const Panel(child:Text('일정·메모·체크 기록은 현재 이 기기에만 저장됩니다. 로그인·클라우드 동기화·자동 백업은 아직 없으며 앱 데이터 삭제 시 기록이 사라집니다.')),
      const SizedBox(height:18),Text('DAYFRAME · MVP 0.3.0',textAlign:TextAlign.center,style:Theme.of(context).textTheme.bodySmall),
    ]);
  }
}
