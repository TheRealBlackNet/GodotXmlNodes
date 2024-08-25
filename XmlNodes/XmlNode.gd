@icon("res://XmlNodes/XmlNodeIcon.svg")
# This is a XML Node able to hold more nodes and attributes
# and has extra features for parsing and creating XML.
extends Node
class_name XmlNode



@export_category("XML")
@export
var nodeattributes:Dictionary = {}
@export
var nodeType:XMLParser.NodeType = XMLParser.NodeType.NODE_ELEMENT
@export
var nodeText:String = ""
@export
var tagName:String = "root"
@export
var noEndTag:bool = false

var depth:int = 0


func addAttributes(key:String, value:String) -> void:
	nodeattributes[key.replace(" ", "_")] = value


# CALL THIS ON ROOT TO GET FULL XML (no pretty print)
func writeXmlLine() -> String:
	# there are child nodes cant <xml/>
	if noEndTag && get_child_count() > 0\
	 || nodeText.length() > 0:
		noEndTag = false
	
	var retval = "";
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
		# REKURSION HIER!
		for child in get_children():
			retval += child.writeXmlLine()
		# END TAG
		retval += "</" + tagName + ">"
	
	return retval



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

##
## FILE
##

func saveXml(path:String) -> void:
	var fileContent:String = self.writeXmlLine()
	var file:FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(fileContent)
	file.flush()
	file.close()

##
## PRINT UTILS
##
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


#static func cleanString(str:String) -> String:
#	return str.replace("\t", " ").strip_escapes().strip_edges()

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


#static func easyPrint(xml:String) -> String:
#	return xml.replace("><",">\r\n<").replace("<!--","\r\n<!--")

#static func DEBUG(parser):
#	print("--" + str(parser.get_current_line()) \
#		+ " \"" + cleanString(parser.get_node_name())\
#		+ "\" DATA:\"" + cleanString(str(parser.get_node_data()))\
#		+ "\" TYPE:" + getNodeTypeString(parser.get_node_type())\
#		+ "\" E:" + str(parser.is_empty())\
#		+ " " + str(parser.get_node_offset()) + " <<")


##
## SPECIAL CONSTRUCTORS
## and ADD NODES
##
static func newComment(comment:String) -> XmlNode:
	var retval:XmlNode = XmlNode.new()
	retval.nodeText = comment
	retval.tagName = ""
	retval.nodeType = XMLParser.NodeType.NODE_COMMENT
	return retval

func addComment(comment:String) -> XmlNode:
	var retval:XmlNode = newComment(comment)
	self.add_child(retval)
	self.noEndTag = false
	retval.depth = self.depth + 1
	return retval

static func newNode(tagName:String) -> XmlNode:
	var retval:XmlNode = XmlNode.new()
	retval.tagName = tagName
	retval.nodeType = XMLParser.NodeType.NODE_ELEMENT
	return retval

func addNode(tagName:String) -> XmlNode:
	var retval:XmlNode = newNode(tagName)
	self.add_child(retval)
	self.noEndTag = false
	retval.depth = self.depth + 1
	return retval

static func newNodeWithText(tagName:String, text:String) -> XmlNode:
	var retval:XmlNode = XmlNode.new()
	retval.tagName = tagName
	retval.nodeText = text
	retval.nodeType = XMLParser.NodeType.NODE_ELEMENT
	return retval

func addNodeWithText(tagName:String, text:String) -> XmlNode:
	var retval:XmlNode = newNodeWithText(tagName, text)
	self.add_child(retval)
	self.noEndTag = false
	retval.depth = self.depth + 1
	return retval

static func newNodeClosed(tagName:String) -> XmlNode:
	var retval:XmlNode = XmlNode.new()
	retval.tagName = tagName
	retval.nodeType = XMLParser.NodeType.NODE_ELEMENT
	retval.noEndTag = true
	return retval

func addNodeClosed(tagName:String) -> XmlNode:
	var retval:XmlNode = newNodeClosed(tagName)
	self.add_child(retval)
	self.noEndTag = false
	retval.depth = self.depth + 1
	return retval

static func newCData(data:String) -> XmlNode:
	var retval:XmlNode = XmlNode.new()
	retval.nodeText = data
	retval.tagName = ""
	retval.nodeType = XMLParser.NodeType.NODE_CDATA
	return retval

func addCData(data:String) -> XmlNode:
	var retval:XmlNode = newCData(data)
	self.add_child(retval)
	self.noEndTag = false
	retval.depth = self.depth + 1
	return retval
