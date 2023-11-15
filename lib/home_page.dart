import 'dart:async';
import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:voice_assistant/feature_box.dart';
import 'package:voice_assistant/openai_services.dart';
import 'package:voice_assistant/pallate.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final speechToText = SpeechToText();
  final flutterTts = FlutterTts();
  String lastWords = '';
  final OpenAIService openAIService = OpenAIService();
  final GlobalKey<FabCircularMenuState> fabKey = GlobalKey();
  TextEditingController _controller = TextEditingController();
  ScrollController _scrollController = ScrollController(keepScrollOffset: false,);

  Timer? autoScrollTimer;
  double _scrollPosition = 0;

  String? generatedContent;
  String? generatedImageUrl;

  bool _isSearching = true;
  String question = "";

  @override
  void initState() {
    super.initState();
    initSpeechToText();
    initTextToSpeech();
    // _startAutoScroll();
  }

  Future<void> initTextToSpeech() async {
    await flutterTts.setSharedInstance(true);
    setState(() {});
  }

  Future<void> initSpeechToText() async {
    await speechToText.initialize();
    setState(() {});
  }

  void resetGeneratedContent() {
    setState(() {
      generatedContent = null;
    });
  }

  Future<void> startListening() async {
    await speechToText.listen(onResult: onSpeechResult);
    setState(() {});
  }

  Future<void> stopListening() async {
    await speechToText.stop();
    setState(() {});
  }

  Future<void> systemSpeak(String content) async {
    await flutterTts.speak(content);
  }

  void onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      lastWords = result.recognizedWords;
    });
  }

  @override
  void dispose() {
    super.dispose();
    speechToText.stop();
    flutterTts.stop();
    // autoScrollTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          leading: Icon(Icons.menu),
          actions: [
            !_isSearching
                ? MaterialButton(
              minWidth: 0,
              child: Icon(Icons.send),
              padding: EdgeInsets.all(10),
              onPressed: () async {
                if (_controller.text.isNotEmpty) {
                  question = _controller.text;
                  _controller.text = "";
                  resetGeneratedContent();

                  // Show a circular progress indicator while waiting for the response
                  showDialog(
                    context: context,
                    builder: (context) {
                      return Center(
                        child: Material(
                          elevation: 78,
                          child: Container(
                              height: 70,
                              width: 150,
                              color: Colors.white,
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(backgroundColor:Colors.white,color:Pallete.mainFontColor,),
                                    SizedBox(width: 10,),
                                    Text("Please Wait")
                                  ],
                                ),
                              )),
                        ),
                      );
                    },
                  );

                  final res = await openAIService.isArtPromptAPI(question);

                  // Close the progress indicator dialog
                  Navigator.of(context).pop();

                  if (res.contains('https')) {
                    generatedContent = null;
                    generatedImageUrl = res;
                  } else {
                    setState(() {
                      generatedContent = res;
                      generatedImageUrl = null;
                    });
                    await systemSpeak(res);
                  }
                  await stopListening();
                }
              },
            )
                : SizedBox(),
            IconButton(
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                });
              },
              icon: _isSearching
                  ? Padding(
                padding: const EdgeInsets.only(right: 18.0),
                child: Icon(Icons.keyboard),
              )
                  : Icon(CupertinoIcons.clear_circled),
            ),
          ],
          centerTitle: true,
          title: _isSearching
              ? Text("Allen")
              : Center(
            child: Container(
              width: 300,
              height: 40,
              child: TextField(
                controller: _controller,
                cursorColor: Colors.grey,
                keyboardType: TextInputType.multiline,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: Pallete.borderColor),
                  ),
                  hintText: "Ask Here...",
                  prefixIcon: Icon(
                    Icons.question_mark_outlined,
                    color: Colors.grey,
                  ),
                  prefixIconColor: Colors.white,
                  hintStyle: TextStyle(color: Colors.grey),
                  alignLabelWithHint: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20),
                ),
                autocorrect: true,
                autofocus: true,
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Column(
                children: [
                  Stack(
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: CircleAvatar(
                            radius: 75,
                            backgroundColor: Pallete.assistantCircleColor,
                          ),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: AssetImage('assets/images/virtualAssistant.png'),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Visibility(
                    visible: generatedContent != null,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      margin: EdgeInsets.symmetric(horizontal: 20).copyWith(top: 30),
                      decoration: BoxDecoration(
                         color: Pallete.secondSuggestionBoxColor,
                        borderRadius: BorderRadius.circular(20).copyWith(topLeft: Radius.zero),
                        border: Border.all(
                          color:Pallete.mainFontColor
                        ),
                      ),
                      child: Text(
                        "You  : " + question,
                        style: TextStyle(
                          color: Pallete.mainFontColor,
                          fontFamily: "Cera Pro",
                          fontSize: 25,
                        ),
                      ),
                    ),
                  ),

                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    margin: EdgeInsets.symmetric(horizontal: 20).copyWith(top: 30),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20).copyWith(topLeft: Radius.zero),
                      border: Border.all(
                        color: Pallete.borderColor,
                      ),
                    ),
                    child: generatedContent == null && generatedImageUrl == null
                        ? Text("How can I assist you?", style: TextStyle(fontSize: 25))
                        : generatedImageUrl != null
                        ? Column(
                      children: [
                        Text("Allen: Here Your Image", style: TextStyle(fontSize: 25)),
                        SizedBox(height: 20,),
                        Image.network(generatedImageUrl!),
                      ],
                    )
                        : TypewriterAnimatedTextKit(
                      isRepeatingAnimation: false,
                      speed: Duration(milliseconds: 75),
                      totalRepeatCount: 1,
                      text: ["Allen : " + generatedContent!],
                      textStyle: TextStyle(
                        color: Pallete.mainFontColor,
                        fontFamily: "Cera Pro",
                        fontSize: 25,
                      ),
                    ),
                  ),

                  Visibility(
                    visible: generatedContent == null && generatedImageUrl==null,
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                          child: Text(
                            "Here are some features of the Application",
                            style: TextStyle(
                              color: Pallete.mainFontColor,
                              fontFamily: "Cera Pro",
                              fontSize: 18,
                            ),
                          ),
                        ),
                        FeatureBox(
                          color: Pallete.firstSuggestionBoxColor,
                          headerText: "ChatGPT",
                          descriptionText: "A smarter way to stay organized and informed with ChatGPT",
                        ),
                        FeatureBox(
                          color: Pallete.secondSuggestionBoxColor,
                          headerText: "Dall-E",
                          descriptionText: "Get inspired and stay creative with your personal assistant powered by Dall-E",
                        ),
                        FeatureBox(
                          color: Pallete.thirdSuggestionBoxColor,
                          headerText: "Smart Voice Assistant",
                          descriptionText: "Get the best of both worlds with a voice assistant powered by Dall-E and ChatGPT",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        floatingActionButton: Builder(
          builder: (context) => FabCircularMenu(
            key: fabKey,
            ringColor: Pallete.mainFontColor,
            alignment: Alignment.bottomRight,
            ringDiameter: 500,
            ringWidth: 150,
            fabSize: 64,
            fabElevation: 8,
            fabIconBorder: CircleBorder(),
            fabColor: Pallete.secondSuggestionBoxColor,
            fabOpenIcon: Icon(Icons.menu),
            fabCloseIcon: Icon(Icons.close_sharp),
            fabMargin: EdgeInsets.all(16),
            animationCurve: Curves.easeInOutCirc,
            children: [
              RawMaterialButton(
                onPressed: () async {
                  if (await speechToText.hasPermission && speechToText.isNotListening) {
                    await startListening();
                  }
                },
                shape: CircleBorder(),
                child: Icon(
                  Icons.mic,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              RawMaterialButton(
                onPressed: () async {
                  if (speechToText.isListening) {
                    question = lastWords;
                    resetGeneratedContent();
                    final resFuture = openAIService.isArtPromptAPI(lastWords);

                    // Show a circular progress indicator while waiting for the response
                    showDialog(
                      context: context,
                      builder: (context) {
                        return Center(
                          child: Material(
                            elevation: 78,
                            child: Container(
                              height: 70,
                                width: 150,
                                color: Colors.white,
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                  CircularProgressIndicator(backgroundColor:Colors.white,color:Pallete.mainFontColor,),
                                  SizedBox(width: 10,),
                                  Text("Please Wait")
                              ],
                            ),
                                )),
                          ),
                        );
                      },
                    );

                    resFuture.then((res) {
                      // Close the progress indicator dialog
                      Navigator.of(context).pop();

                      if (res.contains('https')) {
                        generatedContent = null;
                        generatedImageUrl = res;
                      } else {
                        generatedContent = res;
                        generatedImageUrl = null;
                      }
                      systemSpeak(res);
                      stopListening();
                    });
                  }
                },
                shape: CircleBorder(),
                child: Icon(
                  Icons.stop,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              RawMaterialButton(
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                  });
                  fabKey.currentState?.close();
                },
                shape: CircleBorder(),
                child: Icon(
                  Icons.keyboard,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
