import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

void main() => runApp(const ShochaTeyoApp());

class ShochaTeyoApp extends StatelessWidget {
  const ShochaTeyoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      ),
      home: const MainScaffold(),
    );
  }
}

class Drama { final String id,title,genre,cover; final List<Episode> episodes; Drama({required this.id,required this.title,required this.genre,required this.cover,required this.episodes}); }
class Episode { final int number; final String videoUrl; Episode({required this.number,required this.videoUrl}); }

final sampleDramas = [
  Drama(id: '1', title: 'Cinta Sang CEO Dingin', genre: 'CEO Romantis', cover: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb', episodes: List.generate(50, (i) => Episode(number: i+1, videoUrl: 'https://www.w3schools.com/html/mov_bbb.mp4'))),
  Drama(id: '2', title: 'Terhot: Balas Dendam Istri Sah', genre: 'Terhot', cover: 'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df', episodes: List.generate(50, (i) => Episode(number: i+1, videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4'))),
  Drama(id: '3', title: 'Kekasihku Sang Serigala', genre: 'Werewolf', cover: 'https://images.unsplash.com/photo-1517841905240-472988babdf9', episodes: List.generate(50, (i) => Episode(number: i+1, videoUrl: 'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4'))),
];

class MainScaffold extends StatefulWidget { const MainScaffold({super.key}); @override State<MainScaffold> createState() => _MainScaffoldState(); }
class _MainScaffoldState extends State<MainScaffold> {
  int idx=0, coins=120; bool checkin=false;
  @override void initState(){super.initState(); _load();}
  _load() async { final p=await SharedPreferences.getInstance(); setState((){ coins=p.getInt('coins')??120; checkin=p.getBool('checkin')??false; }); }
  _save(int c) async { final p=await SharedPreferences.getInstance(); await p.setInt('coins', c); setState(()=>coins=c); }
  @override Widget build(BuildContext context){
    return Scaffold(
      body: [HomeFeed(coins: coins, onCoin: _save), const Discover(), Profile(coins: coins, checkin: checkin, onCoin: _save, onCheck: () async { final p=await SharedPreferences.getInstance(); await p.setBool('checkin', true); _save(coins+20); setState(()=>checkin=true); })][idx],
      bottomNavigationBar: NavigationBar(backgroundColor: Colors.black, selectedIndex: idx, onDestinationSelected: (i)=>setState(()=>idx=i), destinations: const [NavigationDestination(icon: Icon(Iconsax.home), label: 'Beranda'), NavigationDestination(icon: Icon(Iconsax.discover), label: 'Eksplor'), NavigationDestination(icon: Icon(Iconsax.profile_circle), label: 'Saya')]),
    );
  }
}

class HomeFeed extends StatefulWidget { final int coins; final Function(int) onCoin; const HomeFeed({super.key,required this.coins,required this.onCoin}); @override State<HomeFeed> createState()=>_HomeFeedState(); }
class _HomeFeedState extends State<HomeFeed>{
  int curDrama=0, curEp=0;
  @override Widget build(BuildContext context){
    return PageView.builder(scrollDirection: Axis.vertical, itemCount: 100, onPageChanged: (i)=>setState((){curDrama=i%sampleDramas.length; curEp=0;}), itemBuilder: (c,i){
      final d=sampleDramas[i%sampleDramas.length]; final ep=d.episodes[curEp]; final locked=ep.number>=45;
      return VideoItem(drama: d, episode: ep, isLocked: locked && widget.coins<15, coins: widget.coins, onUnlock: (){ if(widget.coins>=15){ widget.onCoin(widget.coins-15); } else { showCheckout(context, widget.coins, widget.onCoin); } }, onNext: ()=>setState(()=>curEp=curEp<49?curEp+1:0));
    });
  }
}

class VideoItem extends StatefulWidget { final Drama drama; final Episode episode; final bool isLocked; final int coins; final VoidCallback onUnlock,onNext; const VideoItem({super.key,required this.drama,required this.episode,required this.isLocked,required this.coins,required this.onUnlock,required this.onNext}); @override State<VideoItem> createState()=>_VideoItemState(); }
class _VideoItemState extends State<VideoItem>{
  late VideoPlayerController ctrl; bool liked=false;
  @override void initState(){super.initState(); ctrl=VideoPlayerController.networkUrl(Uri.parse(widget.episode.videoUrl))..initialize().then((_) { ctrl.setLooping(true); ctrl.play(); setState((){}); });}
  @override void dispose(){ctrl.dispose(); super.dispose();}
  @override Widget build(BuildContext context){
    return Stack(fit: StackFit.expand, children:[
      ctrl.value.isInitialized? FittedBox(fit: BoxFit.cover, child: SizedBox(width: ctrl.value.size.width, height: ctrl.value.size.height, child: VideoPlayer(ctrl))): const Center(child: CircularProgressIndicator(color: Color(0xFFFF0050))),
      Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87]))),
      Positioned(left:16,right:80,bottom:30, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[ Text(widget.drama.title, style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 18)), Text('Episode ${widget.episode.number} • ${widget.drama.genre}', style: const TextStyle(color: Colors.white70)), const SizedBox(height:12), if(widget.isLocked) ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFF0050)), onPressed: widget.onUnlock, icon: Icon(Iconsax.lock_1,size:18), label: Text('Buka Kunci - 15 Koin')) else OutlinedButton(onPressed: widget.onNext, child: Text('Episode Berikutnya', style: TextStyle(color: Colors.white))) ])),
      Positioned(right:12,bottom:100, child: Column(children:[ InkWell(onTap: ()=>setState(()=>liked=!liked), child: Column(children:[Icon(liked?Iconsax.heart5:Iconsax.heart,color: liked?Colors.red:Colors.white,size:32), Text(liked?'12,8rb':'12,7rb',style: TextStyle(fontSize:11))])), const SizedBox(height:20), const Icon(Iconsax.message,size:30), const Text('892',style:TextStyle(fontSize:11)), const SizedBox(height:20), const Icon(Iconsax.share,size:30), const Text('Bagikan',style:TextStyle(fontSize:11)), const SizedBox(height:20), Container(padding: EdgeInsets.symmetric(horizontal:10,vertical:6), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)), child: Text('${widget.coins} 🪙',style:TextStyle(fontWeight: FontWeight.bold,fontSize:12)))])),
      if(widget.isLocked) Container(color: Colors.black.withOpacity(0.9), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children:[ Icon(Iconsax.lock_1,size:64), SizedBox(height:16), Text('Episode ${widget.episode.number} Terkunci',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)), Text('Buka dengan 15 koin',style:TextStyle(color:Colors.white70)), SizedBox(height:20), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.white,foregroundColor: Colors.black,padding: EdgeInsets.symmetric(horizontal:32,vertical:14)), onPressed: widget.onUnlock, child: Text('BUKA SEKARANG',style:TextStyle(fontWeight:FontWeight.bold))), TextButton(onPressed: ()=>showCheckout(context, widget.coins, (v){}), child: Text('Koin tidak cukup? Top Up',style:TextStyle(color:Color(0xFFFF0050))))]))),
    ]);
  }
}

class Discover extends StatelessWidget{ const Discover({super.key}); @override Widget build(BuildContext context){ final genres=['Terhot','CEO Romantis','Drama','Werewolf']; return SafeArea(child: ListView(padding: EdgeInsets.all(16), children:[ Text('Eksplor Cerita',style:GoogleFonts.poppins(fontSize:26,fontWeight:FontWeight.bold)), Text('Temukan drama favoritmu',style:TextStyle(color:Colors.white54)), SizedBox(height:20),...genres.map((g)=>Column(crossAxisAlignment:CrossAxisAlignment.start, children:[ Text(g,style:TextStyle(fontSize:17,fontWeight:FontWeight.w600)), SizedBox(height:10), SizedBox(height:180, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: sampleDramas.length, separatorBuilder: (_,__)=>SizedBox(width:12), itemBuilder: (c,i){ final d=sampleDramas[i]; return Container(width:120, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: NetworkImage(d.cover),fit:BoxFit.cover)), child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black87, Colors.transparent])), padding: EdgeInsets.all(8), child: Align(alignment: Alignment.bottomLeft, child: Text(d.title,maxLines:2,style:TextStyle(fontSize:11,fontWeight:FontWeight.bold))))); })), SizedBox(height:20)])) ])); } }

class Profile extends StatelessWidget{ final int coins; final bool checkin; final Function(int) onCoin; final VoidCallback onCheck; const Profile({super.key,required this.coins,required this.checkin,required this.onCoin,required this.onCheck}); @override Widget build(BuildContext context){ return SafeArea(child: Padding(padding: EdgeInsets.all(20), child: Column(children:[ Row(children:[ CircleAvatar(radius:32,backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=5')), SizedBox(width:16), Column(crossAxisAlignment: CrossAxisAlignment.start, children:[ Text('Pecinta Shocha',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)), Text('ID: 88291023',style:TextStyle(color:Colors.white54,fontSize:12)) ])]), SizedBox(height:24), Container(padding: EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFF0050),Color(0xFFFF7A00)]), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[ Column(crossAxisAlignment: CrossAxisAlignment.start, children:[ Text('Dompet Koin Saya',style:TextStyle(color:Colors.white70,fontSize:13)), SizedBox(height:6), Text('$coins Koin',style:TextStyle(fontSize:28,fontWeight:FontWeight.bold)), Text('Berlaku selamanya',style:TextStyle(fontSize:11,color:Colors.white70))]), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.white,foregroundColor: Colors.black), onPressed: ()=>showCheckout(context, coins, onCoin), child: Text('Top Up +',style:TextStyle(fontWeight:FontWeight.bold)))])), SizedBox(height:24), Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[ Column(crossAxisAlignment: CrossAxisAlignment.start, children:[ Text('Check-In Harian',style:TextStyle(fontWeight:FontWeight.bold)), Text('Dapat +20 Koin gratis',style:TextStyle(color:Colors.white54,fontSize:12))]), ElevatedButton(onPressed: checkin?null:onCheck, style: ElevatedButton.styleFrom(backgroundColor: checkin?Colors.grey:Color(0xFFFF0050)), child: Text(checkin?'Selesai':'Ambil'))])) ]))); } }

void showCheckout(BuildContext context,int cur, Function(int) onUpdate){
  showModalBottomSheet(context: context, backgroundColor: Color(0xFF1A1A1A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (ctx)=>Padding(padding: EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children:[
    Center(child: Container(width:40,height:4,decoration:BoxDecoration(color:Colors.white24,borderRadius:BorderRadius.circular(10)))), SizedBox(height:16),
    Text('Pilih Paket Koin',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)), Text('Koin masuk instan setelah bayar',style:TextStyle(color:Colors.white54,fontSize:12)), SizedBox(height:16),
    _pkg(100,'Rp 15.000','Hemat',cur,onUpdate,ctx), _pkg(500,'Rp 70.000','Laris',cur,onUpdate,ctx), _pkg(1200,'Rp 149.000','Terbaik',cur,onUpdate,ctx,best:true),
    SizedBox(height:16), Text('Metode Pembayaran Lokal',style:TextStyle(fontWeight:FontWeight.w600)), SizedBox(height:10),
    Row(children:[ _pay('QRIS',Iconsax.scan_barcode), _pay('GoPay',Iconsax.wallet_3), _pay('DANA',Iconsax.empty_wallet), _pay('OVO',Iconsax.card) ]),
    SizedBox(height:10), Center(child: Text('✓ Simulasi lokal - Tanpa server, pakai SharedPreferences',style:TextStyle(fontSize:10,color:Colors.white30)))
  ])));
}
Widget _pkg(int koin,String harga,String label,int cur,Function(int) onUpdate,BuildContext ctx,{bool best=false}){
  return Container(margin: EdgeInsets.only(bottom:10), decoration: BoxDecoration(border: Border.all(color: best?Color(0xFFFF0050):Colors.white12), borderRadius: BorderRadius.circular(12), color: best?Color(0xFFFF0050).withOpacity(0.1):Colors.transparent), child: ListTile(title: Text('$koin Koin - $label ${best?"🔥":""}',style:TextStyle(fontWeight:FontWeight.bold,fontSize:14)), subtitle: Text(harga,style:TextStyle(color:Colors.white70)), trailing: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFF0050)), onPressed: () async { final p=await SharedPreferences.getInstance(); final n=cur+koin; await p.setInt('coins', n); onUpdate(n); Navigator.pop(ctx); ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Berhasil! +$koin Koin masuk!'),backgroundColor: Colors.green)); }, child: Text('Beli'))));
}
Widget _pay(String n,IconData i){ return Expanded(child: Container(margin: EdgeInsets.only(right:8), padding: EdgeInsets.symmetric(vertical:12), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)), child: Column(children:[ Icon(i,size:20), SizedBox(height:4), Text(n,style:TextStyle(fontSize:11,fontWeight:FontWeight.w600))]))); }
