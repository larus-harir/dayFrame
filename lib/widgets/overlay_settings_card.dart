import 'package:flutter/material.dart';
import '../core/lock_surface.dart';

class OverlaySettingsCard extends StatefulWidget {
  const OverlaySettingsCard({super.key});
  @override State<OverlaySettingsCard> createState()=>_OverlaySettingsCardState();
}
class _OverlaySettingsCardState extends State<OverlaySettingsCard> with WidgetsBindingObserver {
  bool permission=false, running=false, busy=false;
  String? error;
  @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);refresh();}
  @override void dispose(){WidgetsBinding.instance.removeObserver(this);super.dispose();}
  @override void didChangeAppLifecycleState(AppLifecycleState state){if(state==AppLifecycleState.resumed)refresh();}
  Future<void> refresh() async {
    if(!LockSurface.supported)return;
    try {
      final allowed=await LockSurface.overlayPermission();
      final active=await LockSurface.overlayRunning();
      if(mounted)setState((){permission=allowed;running=active;});
    } catch(_){if(mounted)setState(()=>error='네이티브 기능이 포함된 APK로 다시 실행해주세요.');}
  }
  Future<void> act(Future<void> Function() action) async {
    setState((){busy=true;error=null;});
    try{await action();await refresh();}
    catch(_){if(mounted)setState(()=>error='실행에 실패했습니다. 표시 권한과 Android 설정을 확인해주세요.');}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(
    crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text('실제 잠금 위 플래너',style:Theme.of(context).textTheme.titleMedium),
      const Text('화면을 켜면 표시를 시도하며 체크리스트와 성경 읽기를 직접 조작할 수 있습니다. 휴대폰 보안 잠금은 그대로 유지됩니다.'),
      Text('표시 권한: ${permission?"허용됨":"필요"} · 서비스: ${running?"실행 중":"중지"}'),
      if(!permission) FilledButton(onPressed:busy || !LockSurface.supported?null:()=>act(LockSurface.requestOverlayPermission),child:const Text('1. 다른 앱 위에 표시 허용')),
      FilledButton(onPressed:busy || !LockSurface.supported || (!permission && !running)?null:()=>act(running?LockSurface.stopOverlay:LockSurface.startOverlay),
        child:Text(running?'잠금 플래너 중지':'2. 잠금 플래너 시작')),
      if(running) OutlinedButton(onPressed:busy?null:()=>act(LockSurface.showOverlay),child:const Text('지금 실제 화면 열기')),
      const Text('알림에서 중지할 수 있습니다. 재부팅·강제 종료 후 앱에서 다시 시작하세요. 삼성 절전/잠금 정책에 따라 표시가 제한될 수 있습니다.'),
      if(error!=null) Text(error!,style:TextStyle(color:Theme.of(context).colorScheme.error)),
    ],
  )));
}
