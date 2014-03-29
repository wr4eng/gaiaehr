/*
 * File: app/view/MyViewport.js
 *
 * This file was generated by Sencha Architect version 3.0.3.
 * http://www.sencha.com/products/architect/
 *
 * This file requires use of the Ext JS 4.2.x library, under independent license.
 * License of Sencha Architect does not include license for Ext JS 4.2.x. For more
 * details see http://www.sencha.com/license or contact license@sencha.com.
 *
 * This file will be auto-generated each and everytime you save your project.
 *
 * Do NOT hand edit this file.
 */

Ext.define('App.view.MyViewport', {
    extend: 'Ext.container.Viewport',

    requires: [
        'Ext.grid.Panel',
        'Ext.grid.View',
        'Ext.grid.column.Number',
        'Ext.grid.column.Date',
        'Ext.form.field.Date',
        'Ext.form.field.Checkbox',
        'Ext.button.Button',
        'Ext.toolbar.Separator',
        'Ext.grid.plugin.RowEditing',
        'Ext.toolbar.Paging'
    ],

    layout: 'fit',

    initComponent: function() {
        var me = this;

        Ext.applyIf(me, {
            items: [
                {
                    xtype: 'gridpanel',
                    frame: true,
                    itemId: 'usersgrid',
                    margin: 10,
                    title: 'Matcha Connect Test',
                    store: 'UserStore',
                    columns: [
                        {
                            xtype: 'numbercolumn',
                            dataIndex: 'id',
                            text: 'Id'
                        },
                        {
                            xtype: 'gridcolumn',
                            dataIndex: 'fullname',
                            text: 'Fullname',
                            flex: 1,
                            editor: {
                                xtype: 'textfield'
                            }
                        },
                        {
                            xtype: 'datecolumn',
                            dataIndex: 'dob',
                            text: 'Dob',
                            format: 'Y-m-d',
                            editor: {
                                xtype: 'datefield'
                            }
                        },
                        {
                            xtype: 'gridcolumn',
                            width: 200,
                            dataIndex: 'email',
                            text: 'Email',
                            editor: {
                                xtype: 'textfield',
                                vtype: 'email'
                            }
                        },
                        {
                            xtype: 'gridcolumn',
                            dataIndex: 'active',
                            text: 'Active',
                            editor: {
                                xtype: 'checkboxfield'
                            }
                        }
                    ],
                    dockedItems: [
                        {
                            xtype: 'toolbar',
                            dock: 'top',
                            items: [
                                {
                                    xtype: 'button',
                                    itemId: 'addBtn',
                                    text: 'Add User'
                                },
                                {
                                    xtype: 'tbseparator'
                                },
                                {
                                    xtype: 'button',
                                    disabled: true,
                                    itemId: 'removeBtn',
                                    text: 'Remove User'
                                }
                            ]
                        },
                        {
                            xtype: 'pagingtoolbar',
                            dock: 'bottom',
                            width: 360,
                            displayInfo: true,
                            store: 'UserStore'
                        }
                    ],
                    plugins: [
                        Ext.create('Ext.grid.plugin.RowEditing', {

                        })
                    ]
                }
            ]
        });

        me.callParent(arguments);
    }

});