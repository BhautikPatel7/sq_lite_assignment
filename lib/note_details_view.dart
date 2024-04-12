import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/note_database.dart';
import 'package:flutter_application_1/notesview.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class NoteDetailsView extends StatefulWidget {
  const NoteDetailsView({super.key, this.noteId});
  final int? noteId;
  @override
  State<NoteDetailsView> createState() => _NoteDetailsViewState();
}

class _NoteDetailsViewState extends State<NoteDetailsView> {
  NoteDatabase noteDatabase = NoteDatabase.instance;

  TextEditingController titleController = TextEditingController();
  TextEditingController contentController = TextEditingController();

  late NoteModel note;
  bool isLoading = false;
  bool isNewNote = false;
  bool isFavorite = false;


  File? _image; 
  Uint8List? imagebyte;

static final Uint8List empty = Uint8List(0);// Create Empty List To solve Null Error
  final picker = ImagePicker();


  //Image Picker function to get image from gallery
  Future getImageFromGallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
         imagebyte = File(pickedFile.path).readAsBytesSync();
          createNote();
      }
    });
  }

  //Image Picker function to get image from camera
  Future getImageFromCamera() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
       
        createNote();
      }
    });
  }

  //Show options to get image from camera or gallery
  Future showOptions() async {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            child: Text('Photo Gallery'),
            onPressed: () {
              // close the options modal
              Navigator.of(context).pop();
              // get image from gallery
              getImageFromGallery();
            },
          ),
          CupertinoActionSheetAction(
            child: Text('Camera'),
            onPressed: () {
              // close the options modal
              Navigator.of(context).pop();
              // get image from camera
              getImageFromCamera();
            },
          ),
        ],
      ),
    );
  }


  @override
  void initState() {
    refreshNotes();
    super.initState();
  }

///Gets the note from the database and updates the state if the noteId is not null else it sets the isNewNote to true
  refreshNotes() {
    if (widget.noteId == null) {
      setState(() {
        isNewNote = true;
      });
      return;
    }
    noteDatabase.read(widget.noteId!).then((value) {
      setState(() {

        note = value;
        titleController.text = note.title;
        contentController.text = note.content;
        isFavorite = note.isFavorite;
        imagebyte = note.image; //Read image Data from notes database
        if (imagebyte != null) {
          _image = File.fromRawPath(imagebyte ?? empty);
        }
      });
    });
  }

///Creates a new note if the isNewNote is true else it updates the existing note
  createNote() {
    setState(() {
      isLoading = true;
    });
    final model = NoteModel(
      title: titleController.text,
      number: 1,
      content: contentController.text,
      isFavorite: isFavorite,
      image: imagebyte,  //added Image Data 
      createdTime: DateTime.now(),
    );
    if (isNewNote) {
      noteDatabase.create(model);
    } else {
      model.id = note.id;
      noteDatabase.update(model);
    }

    setState(() {
      isLoading = false;
    });
  }

///Deletes the note from the database and navigates back to the previous screen
  deleteNote() {
    noteDatabase.delete(note.id!);
    Navigator.pop(context);
  }

  removedonpressed(){
    _image = null;
    imagebyte = null;
    createNote();
    setState(() {
      
    });
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        actions: [
          IconButton(onPressed: showOptions, icon: Icon(Icons.camera)),
          IconButton(
            onPressed: () {
              setState(() {
                isFavorite = !isFavorite;
              });
            },
            icon: Icon(!isFavorite ? Icons.favorite_border : Icons.favorite),
          ),
          Visibility(
            visible: !isNewNote,
            child: IconButton(
              onPressed: deleteNote,
              icon: const Icon(Icons.delete),
            ),
          ),
          IconButton(
            onPressed: createNote,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(children: [
                  TextField(
                    controller: titleController,
                    cursorColor: Colors.white,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Title',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextField(
                    controller: contentController,
                    cursorColor: Colors.white,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Type your note here...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                   SizedBox(
                    height: MediaQuery.of(context).size.height/3,
                    width: MediaQuery.of(context).size.width/3,
                child: imagebyte != null ? Stack(
                  children: [
                      Container(
                      decoration: BoxDecoration(image: DecorationImage(image: MemoryImage(imagebyte ?? empty))),
                    ),
                    Row(
                      children: [
                        IconButton(onPressed: removedonpressed, icon: Icon(Icons.delete)),
                        Text('Remove Image',style: TextStyle(color: Colors.white,fontSize: 12),)
                      ],
                    ),
                  ],
                ) : Text(''),
                   ),
                ]),
        ),
      ),
    );
  }
}