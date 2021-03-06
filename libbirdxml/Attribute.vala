/*
    Copyright (C) 2014 Johan Mattsson

    This library is free software; you can redistribute it and/or modify 
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 3 of the 
    License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful, but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
    Lesser General Public License for more details.
*/
namespace Bird {

/** 
 * Representation of one XML attribute.
 */
[Compact]
[CCode (ref_function = "bird_attribute_ref", unref_function = "bird_attribute_unref")]
public class Attribute {
	
	public XmlString ns;
	public XmlString name;
	public XmlString content;

	public int refcount = 1;
	
	internal Attribute (XmlString ns, XmlString name, XmlString content) {
		this.ns = ns;
		this.name = name;
		this.content = content;
	}

	internal Attribute.empty () {
		this.ns = new XmlString ("", 0);
		this.name = new XmlString ("", 0);
		this.content = new XmlString ("", 0);
	}
	
	/** Increment the reference count.
	 * @return a pointer to this object
	 */
	public unowned Attribute @ref () {
		refcount++;
		return this;
	}
	
	/** Decrement the reference count and free the object when zero object are holding references to it.*/
	public void unref () {
		if (--refcount == 0) {
			this.free ();
		}
	}
	
	/** 
	 * @return namespace part for this attribute.
	 */
	public string get_namespace () {
		return ns.to_string ();
	}
	
	/**
	 * @return the name of this attribute. 
	 */
	public string get_name () {
		return name.to_string ();
	}

	/** 
	 * @return the value of this attribute.
	 */
	public string get_content () {
		return content.to_string ();
	}
	
	private extern void free ();
}

}
