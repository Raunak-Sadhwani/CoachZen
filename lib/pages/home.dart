import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:slimtrap/components/card.dart';
import 'package:slimtrap/pages/body_form.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      backgroundColor: const Color.fromARGB(255, 83, 98, 210),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.02,
            vertical: height * 0.02,
          ),
          child: Column(
            children: [
              SizedBox(
                height: height * 0.15,
                child: Row(
                  children: [
                    Expanded(
                      child: UICard(children: [
                        Expanded(
                          child: _OpenContainerWrapper(
                            page: const FormPage(),
                            content: Container(
                              color: Colors.blue,
                              child: const Center(
                                child: Text('Form'),
                              ),
                            ),
                            //  onClosed: null,
                          ),
                        ),
                      ]),
                    ),
                    SizedBox(
                      width: width * 0.05,
                    ),
                    Expanded(
                      child: UICard(children: [
                        Expanded(
                          child: _OpenContainerWrapper(
                            page: const FormPage(),
                            content: Container(
                              color: Colors.blue,
                              child: const Center(
                                child: Text('Form'),
                              ),
                            ),
                            //  onClosed: null,
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: OpenContainer(
        transitionType: ContainerTransitionType.fade,
        openBuilder: (BuildContext context, VoidCallback _) {
          return const FormPage();
        },
        closedElevation: 6.0,
        closedColor: Theme.of(context).colorScheme.secondary,
        closedBuilder: (BuildContext context, VoidCallback openContainer) {
          return SizedBox(
            height: 30,
            width: 30,
            child: Center(
              child: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.onSecondary,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OpenContainerWrapper extends StatelessWidget {
  const _OpenContainerWrapper({
    required this.page,
    required this.content,
    // required this.onClosed,
  });

  // final ClosedCallback<bool?> onClosed;
  final Widget page;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return OpenContainer<bool>(
      transitionType: ContainerTransitionType.fade,
      openBuilder: (BuildContext context, VoidCallback _) {
        return page;
      },
      onClosed: null,
      tappable: false,
      closedBuilder: (BuildContext context, VoidCallback openContainer) {
        return GestureDetector(
          onTap: openContainer,
          child: content,
        );
      },
      transitionDuration: const Duration(milliseconds: 600),
    );
  }
}
