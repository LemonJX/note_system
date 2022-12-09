import pymysql
from flask import Flask, render_template, request, redirect

config = {
        'user': "root",
        'password': "yourMySQLpassword",
        'host': "localhost",
        'port': 3306,
        'db': "note_project",
        'charset': "utf8"
}
db = pymysql.connect(**config)

g_err = False
g_username = False
g_notebook = False
g_notebookname = False
g_note = False

app = Flask(__name__)

def register(username,password):
    cur = db.cursor(pymysql.cursors.DictCursor)
    cur.callproc("register", (username, password))
    db.commit()

def checkusername(username):
    cur = db.cursor()
    cur.execute("SELECT checkusername(%s)", username)
    success = cur.fetchone()
    if success[0]:
        return True
    return False

def login(username,password):
    cur = db.cursor()
    cur.execute("SELECT login(%s, %s)", (username, password))
    success = cur.fetchone()
    if success[0]:
        return True
    return False

def modify_page(newPage, note, notebook):
    cur = db.cursor(pymysql.cursors.DictCursor)
    cur.callproc("updateNote", (newPage, g_note, g_notebook))
    db.commit()

@app.route('/edit')
def edit_win():
    cur = db.cursor(pymysql.cursors.DictCursor)
    cur.callproc("getContent", (g_notebook, g_note))
    note = cur.fetchall()
    return render_template('edit.html', content = note[0]["content"])

@app.route('/notebook',methods = ['POST', 'GET'])
def notebook_win():
    global g_err
    if "createNotebook" in request.form:
        new_name = request.form.get('newbook')
        if new_name:
            cur = db.cursor()
            cur.execute("SELECT createNotebook(%s, %s)", (new_name, g_username))
            success = cur.fetchone()
            if success[0]:
                db.commit()
            else:
                g_err = "Duplicate notebook name"
    cur = db.cursor(pymysql.cursors.DictCursor)
    cur.callproc("getAllNotebooks", (g_username,))
    notebooks = cur.fetchall()
    if "searchbook" in request.form:
        searchWord = request.form.get('search')
        if searchWord:
            cur.callproc("getNotebooksBySearch", (g_username,searchWord))
            notebooks = cur.fetchall()
    if "filterbook" in request.form:
        searchTag = request.form.get('selectTag')
        if searchTag:
            cur.callproc("getNotebooksByTag", (g_username, searchTag))
            notebooks = cur.fetchall()
    cur.callproc("getAllBookTags", (g_username,))
    alltags = cur.fetchall()
    if g_err == "Duplicate notebook name":
        temp = g_err
        g_err = False
        return render_template("notebook.html", notebooks = notebooks, alltags = alltags, error = temp)
    return render_template("notebook.html", notebooks = notebooks, alltags = alltags)

@app.route('/note', methods = ["POST", "GET"])
def note_win():
    global g_err
    global g_notebook
    if "deleteTag" in request.form:
        del_tag = request.form.get('selectTag')
        if del_tag:
            cur = db.cursor(pymysql.cursors.DictCursor)
            cur.callproc("deleteBookTag", (del_tag, g_notebook))
            db.commit()
    if "createTag" in request.form:
        new_tag = request.form.get('newtag')
        if new_tag:
            cur = db.cursor(pymysql.cursors.DictCursor)
            cur.callproc("createBookTag", (new_tag, g_notebook))
            db.commit()
    if "deleteNotebook" in request.form:
        cur = db.cursor(pymysql.cursors.DictCursor)
        cur.callproc("deleteNotebook", (g_notebook,))
        db.commit()
        return redirect('/notebook')
    if "createNote" in request.form:
        new_title = request.form.get('newnote')
        if new_title:
            cur = db.cursor()
            cur.execute("SELECT createNote(%s, %s)", (g_notebook, new_title))
            success = cur.fetchone()
            if success[0]:
                db.commit()
            else:
                g_err = "Duplicate title"
    if "selectNotebook" in request.form:
        g_notebook = request.form.get('select')
        if not g_notebook:
            return redirect('/notebook')
    if g_notebook:
        cur = db.cursor(pymysql.cursors.DictCursor)
        cur.callproc("getBookNameById", (g_notebook, ))
        result = cur.fetchall()
        g_notebookname = "Notebook: " + result[0]['nb_name']
        cur.callproc("getAllNotes", (g_notebook, ))
        notes = cur.fetchall()
        cur.callproc("getTagsOfANotebook", (g_notebook,))
        tags = cur.fetchall()
    if "searchnote" in request.form:
        searchWord = request.form.get('search')
        if searchWord:
            cur.callproc("getNotesBySearch", (g_notebook, searchWord))
            notes = cur.fetchall()
    if "filternote" in request.form:
        searchTag = request.form.get('selectTag')
        if searchTag:
            cur.callproc("getNotesByTag", (g_notebook, searchTag))
            notes = cur.fetchall()
    cur.callproc("getAllNoteTags", (g_notebook,))
    alltags = cur.fetchall()
    if g_err == "Duplicate title":
        temp = g_err
        g_err = False
        return render_template("note.html", notebookname = g_notebookname, notes = notes, tags = tags, alltags = alltags, error = temp)
    return render_template("note.html", notebookname = g_notebookname, notes = notes, tags = tags, alltags = alltags)
    
@app.route('/notecontent', methods = ["POST", "GET"])
def notecontent_win():
    global g_note
    if "deleteTag" in request.form:
        del_tag = request.form.get('selectTag')
        if del_tag:
            cur = db.cursor(pymysql.cursors.DictCursor)
            cur.callproc("deleteNoteTag", (del_tag, g_note, g_notebook))
            db.commit()
    if "createTag" in request.form:
        new_tag = request.form.get('newtag')
        if new_tag:
            cur = db.cursor(pymysql.cursors.DictCursor)
            cur.callproc("createNoteTag", (new_tag, g_note, g_notebook))
            db.commit()
    if "deleteNote" in request.form:
        cur = db.cursor(pymysql.cursors.DictCursor)
        cur.callproc("deleteNote", (g_notebook, g_note))
        db.commit()
        return redirect('/note')
    if "selectNote" in request.form:
        g_note = request.form.get('select')
        if not g_note:
            return redirect('/note')
    if "save" in request.form:
        newPage = request.form.get("content")
        modify_page(newPage, g_note, g_notebook)
    if g_note:
        cur = db.cursor(pymysql.cursors.DictCursor)
        cur.callproc("getContent", (g_notebook, g_note))
        content = cur.fetchall()
        cur.callproc("getTagsOfANote", (g_notebook, g_note))
        tags = cur.fetchall()
        return render_template("notecontent.html", content = content[0]['content'], title = g_note, tags = tags)
    return render_template("notecontent.html")

@app.route('/', methods=["GET", "POST"])
def login_win():
    global g_err
    global g_username
    if request.method == "GET":
        if g_err:
            temp = g_err
            g_err = False
            return render_template("login.html", error = temp)
        return render_template("login.html")
    if "submit" in request.form:
        g_username = request.form.get("username")
        passwd = request.form.get("password")
        success = login(g_username, passwd)
        if success:
            g_err = False
            return redirect('/notebook')
        else:
            g_err = "Invalid username or password."
            g_username = False
            return redirect('/')
    elif "register" in request.form:
        return redirect('/register')
    return render_template("login.html")

@app.route("/register", methods=["GET", "POST"])
def register_win():
    global g_err
    if request.method == "GET":
        if g_err:
            temp = g_err
            g_err = False
            return render_template("register.html", error = temp)
        return render_template("register.html")
    if "submit" in request.form:
        temp_user = request.form.get("username")
        temp_passwd = request.form.get("password")
        success = checkusername(temp_user)
        if success:
            register(temp_user, temp_passwd)
            return redirect('/')
        else:
            g_err = "Duplicate username. Please enter a new one."
            return redirect('/register')
    return render_template("register.html")

if __name__ == '__main__':
    app.run(debug = True)
    # db.close()
