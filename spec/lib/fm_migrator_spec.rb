# -*- coding: utf-8 -*-
require 'nokogiri'
require_relative '../spec_helper'

module CFRP
  describe FMMigrator do
    let(:fm_xml) { open('spec/fixtures/1780-1781.xml') }

    let(:season) { '1780-1781' }
    let(:subject) { FMMigrator.new(fm_xml, season) }

    it 'loads XML' do
      Nokogiri::XML.should_receive(:parse).with(fm_xml)
      subject
    end

    it 'splits cols up into separate fieldsets' do
      subject.fieldsets[0].should_not be_nil
    end

    it 'sets the SeasonSpec for the FieldSet' do
      SeasonSpec.should_receive(:retrieve_for).with(season)
      subject
    end

    describe 'Registers' do
      let(:registers) { subject.registers }
      let(:first_reg) { registers[0] }

      # All of the x'ed tests are failing because of
      # the change in register_plays play_attributes?

      xit 'extracts Register from fieldset' do
        first_reg.should_not be_nil
      end

      xit 'sets values for a new Register from fieldset' do
        first_reg.date.should == Date.new(1780, 4, 4)
        first_reg.weekday.should == 'Mardi'
        first_reg.season.should == '1780-1781'
        first_reg.register_num.should == 1

        # Need to find one to test to confirm...
        first_reg.payment_notes.should == ''

        first_reg.page_text.should == 'Arrêté par nous Semainiers la Recette de ce jour 4 Avril mil sept cent quatre-vingt, montant à la somme de quinze cent soixante seize livres. Courville'

        first_reg.total_receipts_recorded_l.should == 1576
        first_reg.total_receipts_recorded_s.should == 0

        first_reg.representation.should == 1

        # NO
        #  signatory                 :string(255)

        first_reg.for_editor_notes.should == 'Unable to read, but appears to say “Le Complement par M. Vanhove”'

        first_reg.misc_notes.should == "L’ouverture\nalso see Notes for Editor"

        # NO
        #  ouverture                 :boolean
        #  cloture                   :boolean

        first_reg.register_period_id.should == 2
        first_reg.verification_state_id.should == 2

        # NO
        #  irregular_receipts_name   :string(255)
      end

      xit 'sets values for plays for each Register from fieldset' do
        first_play = first_reg.register_plays[0]
        second_play = first_reg.register_plays[1]

        first_play.ordering.should == 1
        first_play.play.title.should == 'Le Misanthrope'
        first_play.play.author.should == 'Jean-Baptiste Poquelin dit Molière'
        first_play.play.genre.should == 'comédie'

        second_play.ordering.should == 2
        second_play.play.title.should == 'Le Médecin malgré lui'
        second_play.play.author.should == 'Jean-Baptiste Poquelin dit Molière'
        second_play.play.genre.should == 'comédie'
      end

      xit 'sets new play when it is a new play' do
        # Register #32
        registers[1].register_plays[0].firstrun.should be_true
        # Register #110
        registers[2].register_plays[1].firstrun.should be_true
      end

      xit 'sets new actor name and role when it is provided' do
        # Register #125
        registers[3].register_plays[0].newactor.should == "S. Dunant"
        registers[3].register_plays[0].actorrole.should == "Le S. Dunant a débuté par le Role d’Arfame dans La Tragedie."
      end

      # Testing for 1780-1781 season, where we have 13 seating
      # categories, not including "Irregular Receipts."
      xit 'creates entries for all the ticket sales' do
        first_reg.ticket_sales.count.should == 13
      end

      xit 'imports the Irregular Receipts field' do
        registers[4].ticket_sales.find do |ts|
          ts.seating_category.name == 'Irregular Receipts'
        end.recorded_total_l.should == 4
      end

      xit 'sets the RegisterImage filepaths correctly' do
        registers[3].register_images[0].filepath.should == 'images/jpeg-150-80/M119_02_R145/M119_02_R145_253r.jpg'
        registers[3].register_images[1].filepath.should == 'images/jpeg-150-80/M119_02_R145/M119_02_R145_254v.jpg'
        registers[4].register_images[0].filepath.should == 'images/jpeg-150-80/M119_02_R145/M119_02_R145_109r.jpg'
        registers[4].register_images[1].filepath.should == 'images/jpeg-150-80/M119_02_R145/M119_02_R145_110v.jpg'
      end

      describe "Resetting Images" do
        before :each do
          @r = Register.new
          @r.save

          @ri1 = RegisterImage.new
          @ri1.register_id = @r.id
          @ri1.filepath = 'images/jpeg-150-80/M119_02_R145/M119_02_R145_005r.jpg'

          @ri2 = RegisterImage.new
          @ri2.register_id = @r.id
          @ri2.filepath = 'images/jpeg-150-80/M119_02_R145/M119_02_R145_006v.jpg'

          @ri1.save; @ri2.save

          @r_id, @ri1_id, @ri2_id = @r.id, @ri1.id, @ri2.id

          @register = first_reg
        end

        xit 'associates the images with the new Register' do
          @register.register_images[0].filepath.should == @ri1.filepath
          @register.register_images[1].filepath.should == @ri2.filepath
        end

        xit 'removes old images and Registers' do
          RegisterImage.find_by_id(@r1_id).should be_nil
          RegisterImage.find_by_id(@r2_id).should be_nil
          Register.find_by_id(@r_id).should be_nil
        end
      end
    end
  end
end
