extends Control

@onready var xml_to_save = %XML_TO_SAVE
@onready var xml_loaded = %XML_LOADED
@onready var xml_nodes_here = %XML_NODES_HERE
@onready var xml_as_nodes: Node = %XML_AS_NODES
@onready var xml_path: TextEdit = %XmlPath

var TestFile:String = "res://Example-XmlNodes/TestSmall.xml"

func _on_btn_run_test_button_up() -> void:
	var node:XmlNode = XmlNode.parseXml(xml_path.text)
	if node != null:
		var xmlFile:String = node.writeXmlLine()
		xml_loaded.text = xmlFile
		print(xmlFile)
	else:
		xml_loaded.text = "NULL"



func _on_btn_load_test_file_button_up() -> void:
	var node:XmlNode = XmlNode.parseXml(TestFile)
	if node != null:
		var xmlFile:String = node.writeXmlLine()
		xml_loaded.text = xmlFile
		print(xmlFile)
	else:
		xml_loaded.text = "NULL"



# Dynamic generation (simple) create xml
func _on_btn_node_to_text_button_up() -> void:
	var root:XmlNode = XmlNode.new()
	root.nodeattributes = {\
		"AttributeByCode":"A",\
		"OtherAttributeByCode":"B"}
	root.tagName = "root"
	root.nodeText = "Text"

	var comment1:XmlNode = XmlNode.new()
	comment1.nodeText = "This-is-a-Comment"
	comment1.nodeType = XMLParser.NodeType.NODE_COMMENT
	root.add_child(comment1)
	
	var A1:XmlNode = XmlNode.new()
	A1.tagName = "A1"
	root.add_child(A1)
	
	var A2:XmlNode = XmlNode.new()
	A2.tagName = "A2"
	A2.nodeText = "A"
	root.add_child(A2)
	
	var A3:XmlNode = XmlNode.new()
	A3.tagName = "A3"
	A3.noEndTag = true
	root.add_child(A3)
	
	var A4:XmlNode = XmlNode.new()
	A4.tagName = "A4"
	root.add_child(A4)
	
	var CData:XmlNode = XmlNode.new()
	CData.nodeText = "CDATA_CONTENT"
	CData.nodeType = XMLParser.NodeType.NODE_CDATA
	A4.add_child(CData)
	
	var xmlFile:String = root.writeXmlLine()
	xml_loaded.text = xmlFile
	print(xmlFile)

# nodes created by special constructors
func _on_btn_fancy_create_button_up() -> void:
	var root:XmlNode = XmlNode.newNodeWithText("root", "Text")
	root.addAttributes("Att1", "A")
	root.addAttributes("Att2", "B")
	var comment1:XmlNode = XmlNode.newComment("A comment here")
	root.add_child(comment1)
	var A1:XmlNode = XmlNode.newNode("A1")
	root.add_child(A1)
	var A2:XmlNode = XmlNode.newNodeWithText("A2", "A")
	root.add_child(A2)
	var A3:XmlNode = XmlNode.newNodeClosed("A3")
	root.add_child(A3)
	var A4:XmlNode = XmlNode.newNode("A4")
	root.add_child(A4)
	var CData:XmlNode = XmlNode.newCData("CDATA-CONTENT-HERE")
	A4.add_child(CData)
	
	var xmlFile:String = root.writeXmlLine()
	xml_loaded.text = xmlFile
	print(xmlFile)

# most fancy way to make nodes:
# info its not root that return but the created node!
func _on_btn_more_fancy_create_button_up() -> void:
	var root:XmlNode = XmlNode.newNodeWithText("root", "Text")
	root.addAttributes("Att1", "A")
	root.addAttributes("Att2", "B")
	root.addComment("Test Comment")
	root.addNode("A1")
	root.addNodeWithText("A2", "A2Text")
	root.addNodeClosed("A3")
	root.addNode("A4").addCData("CDATA-HERE-ADDED")
	
	var xmlFile:String = root.writeXmlLine()
	xml_loaded.text = xmlFile
	print(xmlFile)


# Takes the nodes from the editor and prints them as text:
func _on_btn_editor_node_to_text_button_up() -> void:
	var root:XmlNode = xml_as_nodes.get_child(0);
	var xmlFile:String = root.writeXmlLine()
	xml_loaded.text = xmlFile
	print(xmlFile)


func _on_btn_load_test_file_deep_button_up() -> void:
	var node:XmlNode = XmlNode.parseXml("res://Example-XmlNodes/DeepNodes.xml")
	if node != null:
		var xmlFile:String = node.writeXmlLine()
		xml_loaded.text = xmlFile
		print(xmlFile)
	else:
		xml_loaded.text = "NULL"


func _on_btn_load_test_file_testing_button_up() -> void:
	var node:XmlNode = XmlNode.parseXml("res://Example-XmlNodes/Testing.xml")
	if node != null:
		var xmlFile:String = node.writeXmlLine()
		xml_loaded.text = xmlFile
		print(xmlFile)
	else:
		xml_loaded.text = "NULL"


func _on_btn_test_escapes_button_up() -> void:
	pass # Replace with function body.
