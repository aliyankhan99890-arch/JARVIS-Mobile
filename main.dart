import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

void main() => runApp(const JarvisApp());

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JARVIS Secure',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF050A12),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C8FF),
          brightness: Brightness.dark,
        ),
      ),
      home: const SecurityGate(),
    );
  }
}

class SecurityGate extends StatefulWidget {
  const SecurityGate({super.key});
  @override State<SecurityGate> createState() => _SecurityGateState();
}

class _SecurityGateState extends State<SecurityGate> {
  final auth = LocalAuthentication();
  bool checking = true;
  String message = 'SECURE ACCESS';

  @override
  void initState() {
    super.initState();
    _unlock();
  }

  Future<void> _unlock() async {
    try {
      final can = await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (!can) {
        setState(() { checking=false; message='Device authentication is unavailable'; });
        return;
      }
      final ok = await auth.authenticate(
        localizedReason: 'Authenticate to access your private JARVIS',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      if (!mounted) return;
      if (ok) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const JarvisHome()));
      } else {
        setState(() { checking=false; message='ACCESS DENIED'; });
      }
    } catch (_) {
      if (mounted) setState(() { checking=false; message='Authentication failed'; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.shield_outlined, size: 90, color: Color(0xFF00C8FF)),
        const SizedBox(height: 20),
        const Text('J A R V I S', style: TextStyle(fontSize: 27, letterSpacing: 8, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(message, style: const TextStyle(color: Color(0xFF00C8FF), letterSpacing: 2)),
        const SizedBox(height: 28),
        if (!checking)
          FilledButton.icon(
            onPressed: () { setState(()=>checking=true); _unlock(); },
            icon: const Icon(Icons.fingerprint),
            label: const Text('AUTHENTICATE'),
          ),
      ]),
    ),
  );
}

class JarvisHome extends StatefulWidget {
  const JarvisHome({super.key});
  @override State<JarvisHome> createState() => _JarvisHomeState();
}

class _JarvisHomeState extends State<JarvisHome> {
  final speech = stt.SpeechToText();
  final tts = FlutterTts();
  final auth = LocalAuthentication();
  final input = TextEditingController();
  final messages = <Map<String,String>>[];
  bool listening=false;
  String status='READY';

  @override
  void initState() {
    super.initState();
    tts.setLanguage('en-US');
    tts.setSpeechRate(.48);
  }

  Future<bool> _deviceAuth(String reason) async {
    try {
      return await auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) { return false; }
  }

  Future<void> _listen() async {
    if (listening) {
      await speech.stop();
      setState(() { listening=false; status='READY'; });
      return;
    }
    if (!await _deviceAuth('Authenticate before using private JARVIS commands')) {
      setState(()=>status='ACCESS DENIED');
      return;
    }
    final ok=await speech.initialize();
    if (!ok) { await _say('Sir, speech recognition is not available.'); return; }
    setState(() { listening=true; status='LISTENING...'; });
    await speech.listen(
      localeId:'en_US',
      onResult:(r) {
        input.text=r.recognizedWords;
        if (r.finalResult) {
          setState(()=>{listening=false; status='PROCESSING...';});
          _handle(input.text);
        }
      },
    );
  }

  Future<void> _say(String text) async {
    setState(()=>messages.add({'role':'JARVIS','text':text}));
    setState(()=>status='SPEAKING...');
    await tts.speak(text);
    setState(()=>status='READY');
  }

  Future<void> _handle(String q) async {
    final text=q.trim();
    if (text.isEmpty) { setState(()=>status='READY'); return; }
    setState(()=>messages.add({'role':'YOU','text':text}));
    input.clear();
    final l=text.toLowerCase();

    if (l.contains('note')) {
      final p=await SharedPreferences.getInstance();
      await p.setString('jarvis_note', text);
      await _say('Sir, your note is securely saved on this device.');
    } else if (l.contains('hello') || l.contains('salam') || l.contains('hi')) {
      await _say('Hello Sir. Secure JARVIS is ready.');
    } else if (l.contains('time')) {
      final n=DateTime.now();
      await _say('Sir, the current time is ${n.hour.toString().padLeft(2,'0')}:${n.minute.toString().padLeft(2,'0')}.');
    } else {
      await _say('Command authenticated. AI brain connection is ready to be added securely.');
    }
    setState(()=>status='READY');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('J A R V I S', style: TextStyle(letterSpacing:6,fontWeight:FontWeight.w700)),
      centerTitle:true, backgroundColor:Colors.transparent,
      actions:[IconButton(onPressed:() async {
        if (await _deviceAuth('Authenticate to open JARVIS security settings')) {
          if (mounted) showDialog(context:context,builder:(_)=>const AlertDialog(
            title:Text('Security'),
            content:Text('Device authentication is enabled. Voice enrollment and speaker verification require a dedicated on-device speaker-recognition model in the next security module.'),
          ));
        }
      }, icon:const Icon(Icons.security))]
    ),
    body: SafeArea(child:Column(children:[
      const SizedBox(height:18),
      Container(width:190,height:190,
        decoration:BoxDecoration(
          shape:BoxShape.circle,
          border:Border.all(color:const Color(0xFF00C8FF),width:2),
          boxShadow:[BoxShadow(color:const Color(0xFF00C8FF).withOpacity(.25),blurRadius:45,spreadRadius:10)],
          gradient:const RadialGradient(colors:[Color(0xFF103B52),Color(0xFF06101B),Color(0xFF050A12)]),
        ),
        child:const Center(child:Icon(Icons.shield_outlined,size:86,color:Color(0xFF00C8FF))),
      ),
      const SizedBox(height:12),
      Text(status,style:const TextStyle(color:Color(0xFF00C8FF),letterSpacing:3,fontWeight:FontWeight.bold)),
      const SizedBox(height:14),
      Expanded(child:messages.isEmpty
        ? const Center(child:Text('SECURE JARVIS\n\nAuthenticate, then tap the microphone.',textAlign:TextAlign.center,style:TextStyle(color:Colors.white54,fontSize:16)))
        : ListView.builder(padding:const EdgeInsets.symmetric(horizontal:16),itemCount:messages.length,
            itemBuilder:(c,i)=>Align(
              alignment:messages[i]['role']=='YOU'?Alignment.centerRight:Alignment.centerLeft,
              child:Container(margin:const EdgeInsets.symmetric(vertical:6),padding:const EdgeInsets.all(13),
                constraints:const BoxConstraints(maxWidth:330),
                decoration:BoxDecoration(
                  color:messages[i]['role']=='YOU'?const Color(0xFF073B52):const Color(0xFF101923),
                  borderRadius:BorderRadius.circular(16),border:Border.all(color:const Color(0xFF1A5064))),
                child:Text('${messages[i]['role']}: ${messages[i]['text']}'),
              ),
            ))),
      Padding(padding:const EdgeInsets.fromLTRB(12,4,12,12),child:Row(children:[
        Expanded(child:TextField(controller:input,onSubmitted:_handle,
          decoration:InputDecoration(hintText:'Ask JARVIS...',filled:true,fillColor:const Color(0xFF0C1624),
            border:OutlineInputBorder(borderRadius:BorderRadius.circular(22),borderSide:BorderSide.none),
            contentPadding:const EdgeInsets.symmetric(horizontal:18,vertical:13)))),
        const SizedBox(width:8),
        FloatingActionButton(onPressed:_listen,backgroundColor:listening?const Color(0xFF007FA3):const Color(0xFF00A8D6),
          child:Icon(listening?Icons.stop:Icons.mic)),
      ]))
    ]))
  );

  @override void dispose(){input.dispose();speech.stop();tts.stop();super.dispose();}
}
