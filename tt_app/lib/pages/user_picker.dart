import 'package:flutter/material.dart';

class UserPickerPage extends StatefulWidget {

    final String initialUserName;

    UserPickerPage({ Key key, String userName }):
        initialUserName = userName,
        super(key: key);

    @override
    State<UserPickerPage> createState() => _UserPickerPageState();
}

class _UserPickerPageState extends State<UserPickerPage> {

    final _textController = TextEditingController();

    @override
    void initState() {
        super.initState();
        _textController.text = widget.initialUserName;
    }

    @override
    Widget build(BuildContext context) {

        final theme = Theme.of(context);

        return Scaffold(
            appBar: AppBar(
                title: Text('Timeline User'),
            ),
            resizeToAvoidBottomPadding: false,
            body: Padding(
                padding: EdgeInsets.all(16.0),
                child: SafeArea(
                    child: Form(
                        child: Row(
                            children: [
                                Expanded(child:
                                    TextFormField(
                                        controller: _textController,
                                        textInputAction: TextInputAction.go,
                                        autocorrect: false,
                                        decoration: InputDecoration(
                                            labelText: 'User',
                                            hintText: 'elonmusk',
                                        ),
                                        onFieldSubmitted: (s) {
                                            Navigator.pop(context, s);
                                        }
                                    ),
                                ),
                                SizedBox(width: 16),
                                FlatButton(
                                    color: theme.accentColor,
                                    onPressed: () {
                                        // dismiss the focus to avoid the home page content shifting
                                        FocusScope.of(context).requestFocus(new FocusNode());
                                        Future.delayed(Duration(milliseconds: 300), () {
                                            Navigator.pop(context, _textController.text);
                                        });
                                    },
                                    child: Text("Save", style: theme.accentTextTheme.button)
                                )
                            ],
                        ),
                    )
                ),
            )
        );
    }
}