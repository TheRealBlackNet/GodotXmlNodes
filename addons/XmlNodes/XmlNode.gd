@icon("res://addons/XmlNodes/XmlNodeIcon.svg")
## This is a XML Node able to hold more nodes and attributes
## and has extra features for parsing and creating XML.
## @tutorial: https://github.com/TheRealBlackNet/GodotXmlNodes/wiki/Tutorial-%E2%80%90-Usage-guide
extends Node
class_name XmlNode


@export_category("XML")
## A map with string\string pairs that are the attributes of a xml node. 
## please be responsible with the keys because i cant protect the map
## in gd script and want to edit it editor: no numbers at start
## no spaces in the name just XML rules here.
@export
var nodeattributes:Dictionary = {}
## The type of the node only use NODE_ELEMENT, NODE_COMMENT and NODE_CDATA!
@export
var nodeType:XMLParser.NodeType = XMLParser.NodeType.NODE_ELEMENT
## the text inside your node <root>text</root>
@export
var nodeText:String = ""
## the tag name default is <root />
@export
var tagName:String = "root"
## if true a closing tag will be created <root></root>
## if not its a <root /> node this will be ignored if 
## sub nodes are added! (and set to false while exporting)
@export
var noEndTag:bool = false

## internal counter for the layers in the xml
## can be used for a formatter
var depth:int = 0

## correct and save way to add a attribute 
## replaces space with underlines!
func addAttributes(key:String, value:String) -> void:
	# also should not start with a number
	nodeattributes[key.replace(" ", "_")] = value

#
#
# SEARCH
#
#

## searches the childnodes for a tag name: <root />
## and return a array of nodes 
func searchNodesByTagName(tagName:String) -> Array[XmlNode]:
	var retval:Array[XmlNode] = []
	
	# add self then run for children:
	#if tagName == self.tagName:
	#	retval.append(self)
	#for child in get_children():
	#	retval.append_array(child.searchNodesByTagName(tagName))
	# CON: call for each node... 
	
	# self was added above test children
	# only run if children are there
	for child:XmlNode in get_children():
		if tagName == child.tagName:
			retval.append(child)
		if child.get_child_count() > 0:
			retval.append_array(child.searchNodesByTagName(tagName))
	
	return retval


## returns all nodes in a array by attribute name and value
func searchNodesByAttributeNameValue(\
		attributeName:String,\
		attributeValue:String
		) -> Array[XmlNode]:
	var retval:Array[XmlNode] = []
	for child:XmlNode in get_children():
		var valOrNull:String = child.nodeattributes.get(attributeName)
		if valOrNull != null \
				&& attributeValue == valOrNull:
			retval.append(child)
		if child.get_child_count() > 0:
			retval.append_array(child\
				.searchNodesByAttributeNameValue(\
					attributeName, attributeValue))
	return retval


## searches attributes with id 
func searchNodesById(attributeValue:String) -> Array[XmlNode]:
	return self.searchNodesByAttributeNameValue("id", attributeValue)

## searches attributes with name
func searchNodesByName(attributeValue:String) -> Array[XmlNode]:
	return self.searchNodesByAttributeNameValue("name", attributeValue)


#
#
#
# PRINT
#
#
#


## returns the xml from this point down 
## call this function on root to get the full xml
## (no pretty print here)
func writeXmlLine() -> String:
	# there are child nodes cant <xml/>
	if noEndTag && get_child_count() > 0\
	 || nodeText.length() > 0:
		noEndTag = false
	
	var retval = "<?xml version='1.0' encoding='utf-8' ?>\r\n";
	# -- OPENING TAG --
	if nodeType == XMLParser.NodeType.NODE_COMMENT:
		retval += "<!-- " + nodeText
	elif nodeType == XMLParser.NodeType.NODE_CDATA:
		retval += "<![CDATA[" + nodeText
	else:
		retval += "<" + tagName
	
	# -- ATTRIBUTES --
	for currentNodeKey in nodeattributes:
		var value:String = nodeattributes[currentNodeKey]
		retval += " "\
			+ currentNodeKey\
			+ "=\""\
			+ value\
			+ "\""
	
	# -- CLOSING TAG --
	if nodeType == XMLParser.NodeType.NODE_COMMENT:
		retval += " -->"
	elif nodeType == XMLParser.NodeType.NODE_CDATA:
		retval += "]]>"
	elif noEndTag:
		retval += "/>"
	else:
		retval += ">" + nodeText
		# REKURSION:
		for child in get_children():
			retval += child.writeXmlLine()
		# END TAG
		retval += "</" + tagName + ">"
	
	return retval


## this methods loads a file and return the XML tree:
static func parseXml(path:String) -> XmlNode:
	var parser:XMLParser = XMLParser.new()
	parser.open(path)
	
	var root:XmlNode = null
	var last:XmlNode = null
	var nodeStack:Array = []
	
	while parser.read() != ERR_FILE_EOF:
		if null == root\
			&& parser.get_node_type() == XMLParser.NodeType.NODE_ELEMENT:
			# --- ROOT ---
			if parser.is_empty():
				root = XmlNode.newNodeClosed(parser.get_node_name())
			else:
				root = XmlNode.newNode(parser.get_node_name())
			last = root
			nodeStack.push_back(last)
			# ATTRIBUTES
			for idx in range(parser.get_attribute_count()):
				last.addAttributes(\
					parser.get_attribute_name(idx),\
					parser.get_attribute_value(idx))
			#
		elif parser.get_node_type() == XMLParser.NodeType.NODE_TEXT:
			last.nodeText = (last.nodeText\
				+ " "\
				+ unescapeText(parser.get_node_data()))\
				.strip_edges()
		elif parser.get_node_type() == XMLParser.NodeType.NODE_ELEMENT:
			if parser.is_empty():
				last = last.addNodeClosed(parser.get_node_name())
			else:
				last = last.addNode(parser.get_node_name())
			nodeStack.push_back(last)
			# ATTRIBUTES
			for idx in range(parser.get_attribute_count()):
				last.addAttributes(\
					parser.get_attribute_name(idx),\
					parser.get_attribute_value(idx))
			#
		elif parser.get_node_type() == XMLParser.NodeType.NODE_COMMENT:
			# dont push and set last for comments they cant have sub nodes
			last.addComment(parser.get_node_name().strip_edges())
		elif parser.get_node_type() == XMLParser.NodeType.NODE_CDATA:
			# no sub nodes
			last.addCData(parser.get_node_name())
		elif  parser.get_node_type() == XMLParser.NodeType.NODE_ELEMENT_END:
			nodeStack.pop_back()
			if !nodeStack.is_empty():
				last = nodeStack[-1]
			else:
				last = null
	return root


## save the current tree into a file 
## call it at root to export the full tree
func saveXml(path:String) -> void:
	var fileContent:String = self.writeXmlLine()
	var file:FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(fileContent)
	file.flush()
	file.close()

#
#
# PRINT UTILS
#
#

## turn the node type into a display name
static func getNodeTypeString(nt:int) -> String:
	if nt == XMLParser.NodeType.NODE_NONE:
		return "NONE"
	elif nt == XMLParser.NodeType.NODE_ELEMENT:
		return "ELEMENT_START"
	elif nt == XMLParser.NodeType.NODE_ELEMENT_END:
		return "ELEMENT_END"
	elif nt == XMLParser.NodeType.NODE_TEXT:
		return "TEXT"
	elif nt == XMLParser.NodeType.NODE_COMMENT:
		return "COMMENT"
	elif nt == XMLParser.NodeType.NODE_CDATA:
		return "CDATA"
	elif nt == XMLParser.NodeType.NODE_UNKNOWN:
		return "UNKNOWN"
	else:
		return "ERROR"

## lt to  <
static func unescapeText(str:String) -> String:
	return str.replace("\t", " ")\
		.replace("\r\n", " ")\
		.replace("\n", " ")\
		.replace("  ", " ")\
		.replace("&lt;", "<")\
		.replace("&gt;", ">" )\
		.replace("&amp;", "&")\
		.replace("&quot;", "\"")\
		.strip_edges()

## < to lt
static func escapeText(str:String) -> String:
	return str.replace("\t", " ")\
		.replace("\r\n", " ")\
		.replace("\n", " ")\
		.replace("  ", " ")\
		.replace("<", "&lt;")\
		.replace(">", "&gt;")\
		.replace("&", "&amp;")\
		.replace("\"", "&quot;")\
		.strip_edges()

## insert line breaks into xml string (for debug print)
static func simpleFotmat(xml:String) -> String:
	return xml.replace(">",">\r\n").replace("<!--","\r\n<!--")


#static func cleanString(str:String) -> String:
#	return str.replace("\t", " ").strip_escapes().strip_edges()

#static func DEBUG(parser):
#	print("--" + str(parser.get_current_line()) \
#		+ " \"" + cleanString(parser.get_node_name())\
#		+ "\" DATA:\"" + cleanString(str(parser.get_node_data()))\
#		+ "\" TYPE:" + getNodeTypeString(parser.get_node_type())\
#		+ "\" EMPTY:" + str(parser.is_empty())\
#		+ " " + str(parser.get_node_offset()) + " <<")

#
#
#
# SPECIAL CONSTRUCTORS AND ADD NODES
#
#
#

## new comment - text will be set <!-- text -->
static func newComment(comment:String) -> XmlNode:
	var retval:XmlNode = XmlNode.new()
	retval.name = "Comment"
	retval.nodeText = comment
	retval.tagName = ""
	retval.nodeType = XMLParser.NodeType.NODE_COMMENT
	return retval

## creates a comment and adds it into the current node 
## return the new node
func addComment(comment:String) -> XmlNode:
	var retval:XmlNode = newComment(comment)
	retval.depth = self.depth + 1
	self.add_child(retval)
	self.noEndTag = false
	return retval

## creates a new node - tagname will be set
static func newNode(tagName:String) -> XmlNode:
	var retval:XmlNode = XmlNode.new()
	retval.name = tagName
	retval.tagName = tagName
	retval.nodeType = XMLParser.NodeType.NODE_ELEMENT
	return retval

## creates a node and adds it into the current node 
## return the new node
func addNode(tagName:String) -> XmlNode:
	var retval:XmlNode = newNode(tagName)
	retval.depth = self.depth + 1
	self.add_child(retval)
	self.noEndTag = false
	return retval

## creates a new node - tagname will be set
static func newNodeWithText(tagName:String, text:String) -> XmlNode:
	var retval:XmlNode = XmlNode.new()
	retval.tagName = tagName
	retval.nodeText = text
	retval.nodeType = XMLParser.NodeType.NODE_ELEMENT
	return retval

## creates a node and adds it into the current node 
## return the new node
func addNodeWithText(tagName:String, text:String) -> XmlNode:
	var retval:XmlNode = newNodeWithText(tagName, text)
	retval.depth = self.depth + 1
	self.add_child(retval)
	self.noEndTag = false
	return retval

## creates a new node - tagname will be set <tag />
static func newNodeClosed(tagName:String) -> XmlNode:
	var retval:XmlNode = XmlNode.new()
	retval.name = tagName
	retval.tagName = tagName
	retval.nodeType = XMLParser.NodeType.NODE_ELEMENT
	retval.noEndTag = true
	return retval

## creates a node and adds it into the current node 
## return the new node
func addNodeClosed(tagName:String) -> XmlNode:
	var retval:XmlNode = newNodeClosed(tagName)
	retval.depth = self.depth + 1
	self.add_child(retval)
	self.noEndTag = false
	return retval

## new CDATA block
static func newCData(data:String) -> XmlNode:
	var retval:XmlNode = XmlNode.new()
	retval.name = "CDATA"
	retval.nodeText = data
	retval.tagName = ""
	retval.nodeType = XMLParser.NodeType.NODE_CDATA
	return retval

## new CDATA block will be added to current node
func addCData(data:String) -> XmlNode:
	var retval:XmlNode = newCData(data)
	retval.depth = self.depth + 1
	self.add_child(retval)
	self.noEndTag = false
	return retval


## adding nodes from search into current node 
## will be duplicates!
func addNodesFromArray(nodes:Array[XmlNode]) -> void:
		if nodes != null && !nodes.is_empty():
			for cur:XmlNode in nodes:
				self.add_child(cur.duplicate())
			self.noEndTag = false
